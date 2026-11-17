defmodule ChennaiAssist.AlertsTest do
  # Not async: changes application env for the Telegram API.
  use ChennaiAssist.DataCase, async: false

  alias ChennaiAssist.{Alerts, Chat, FakeTelegram, HelpDesk, Settings, Telegram}

  setup do
    FakeTelegram.setup_fake(&start_supervised!/1)
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
    # The test endpoint is plain http, so the reply webhook is not registered.
    assert {:ok, "Jithin", :replies_off} = Telegram.link_latest_chat()
    assert_receive {:telegram, "TEST-TOKEN", "deleteWebhook", _}
    assert_receive {:telegram, "TEST-TOKEN", "getUpdates", _}
    refute_receive {:telegram, _, "setWebhook", _}, 100
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
    assert Alerts.parse_reference(text) == {:chat, conv.id}
    assert_receive {:admin_alert, %{url: url}}
    assert url == "/admin/chats/#{conv.id}"
    refute_receive {:telegram, _, "sendMessage", _}, 200

    # Admin replies do not alert.
    {:ok, _} = Chat.send_message(conv, "admin", "Yes!")
    refute_receive {:telegram, _, "sendMessage", _}, 200

    {:ok, q} =
      HelpDesk.ask_question(%{
        "name" => "Meena",
        "email" => "m@example.com",
        "category" => "food",
        "body" => "Best filter coffee near Mylapore?"
      })

    assert_receive {:telegram, _, "sendMessage", %{"text" => q_text}}
    assert q_text =~ "❓ New question from Meena"
    assert Alerts.parse_reference(q_text) == {:question, q.id}
  end

  test "parse_reference uses the trailing reference, not one quoted in a message" do
    assert Alerts.parse_reference("💬 Ravi: see Chat #3 please\nChat #12\n\n↩️ ...") == {:chat, 12}
    assert Alerts.parse_reference("hello") == :none
    assert Alerts.parse_reference(nil) == :none
  end
end
