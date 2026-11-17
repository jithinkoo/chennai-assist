defmodule ChennaiAssist.AlertsTest do
  # Not async: changes application env for the Telegram API.
  use ChennaiAssist.DataCase, async: false

  alias ChennaiAssist.{Alerts, Chat, HelpDesk, Settings, Telegram}

  defmodule FakeTelegram do
    @moduledoc false
    # Minimal stand-in for api.telegram.org: forwards each call to the test.
    use Plug.Router
    plug :match
    plug Plug.Parsers, parsers: [:json], json_decoder: Jason
    plug :dispatch

    post "/bot:token/:method" do
      send(:alerts_test, {:telegram, token, method, conn.body_params})

      result =
        case method do
          "getUpdates" ->
            [
              %{"message" => %{"chat" => %{"type" => "group", "id" => -5}}},
              %{"message" => %{"chat" => %{"type" => "private", "id" => 4242, "first_name" => "Jithin"}}}
            ]

          _ ->
            %{"message_id" => 1}
        end

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{"ok" => true, "result" => result}))
    end
  end

  setup do
    Process.register(self(), :alerts_test)
    port = 40_000 + :rand.uniform(9_000)
    start_supervised!({Bandit, plug: FakeTelegram, port: port, ip: {127, 0, 0, 1}, startup_log: false})

    Application.put_env(:chennai_assist, :telegram_api, "http://127.0.0.1:#{port}")
    Application.put_env(:chennai_assist, :telegram_bot_token, "TEST-TOKEN")

    on_exit(fn ->
      Application.delete_env(:chennai_assist, :telegram_api)
      Application.delete_env(:chennai_assist, :telegram_bot_token)
      Application.delete_env(:chennai_assist, :telegram_chat_id)
    end)

    # Background Telegram sends run in Tasks that need DB access.
    Ecto.Adapters.SQL.Sandbox.mode(ChennaiAssist.Repo, {:shared, self()})
    :ok
  end

  test "nothing is sent until a chat is linked" do
    refute Telegram.ready?()
    Alerts.subscribe()
    {:ok, _} = Chat.start_conversation(%{"visitor_name" => "Ravi", "visitor_email" => "r@example.com"})

    # Browser alert still fires; Telegram does not.
    assert_receive {:admin_alert, %{title: "New chat: Ravi"}}
    refute_receive {:telegram, _, "sendMessage", _}, 200
  end

  test "link_latest_chat saves the most recent private chat" do
    assert {:ok, "Jithin"} = Telegram.link_latest_chat()
    assert_receive {:telegram, "TEST-TOKEN", "getUpdates", _}
    assert Settings.get("telegram_chat_id") == "4242"
    assert Telegram.ready?()
  end

  test "visitor messages and questions alert Telegram and the browser" do
    {:ok, _} = Settings.put("telegram_chat_id", "4242")
    Alerts.subscribe()

    {:ok, conv} =
      Chat.start_conversation(%{
        "visitor_name" => "Ravi",
        "visitor_email" => "r@example.com",
        "message" => "Is Velachery good for families?"
      })

    # A chat that starts with a message alerts once, with the message.
    assert_receive {:telegram, _, "sendMessage", %{"chat_id" => "4242", "text" => text}}
    assert text =~ "💬 Ravi: Is Velachery good for families?"
    assert text =~ "/admin/chats/#{conv.id}"
    assert_receive {:admin_alert, %{url: url}}
    assert url == "/admin/chats/#{conv.id}"
    refute_receive {:telegram, _, "sendMessage", _}, 200

    # Admin replies do not alert.
    {:ok, _} = Chat.send_message(conv, "admin", "Yes!")
    refute_receive {:telegram, _, "sendMessage", _}, 200

    {:ok, _} =
      HelpDesk.ask_question(%{
        "name" => "Meena",
        "email" => "m@example.com",
        "category" => "food",
        "body" => "Best filter coffee near Mylapore?"
      })

    assert_receive {:telegram, _, "sendMessage", %{"text" => q_text}}
    assert q_text =~ "❓ New question from Meena"
  end
end
