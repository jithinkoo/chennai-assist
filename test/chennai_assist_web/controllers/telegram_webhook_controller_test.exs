defmodule ChennaiAssistWeb.TelegramWebhookControllerTest do
  use ChennaiAssistWeb.ConnCase, async: false

  alias ChennaiAssist.{Chat, FakeTelegram, HelpDesk, Settings, Telegram}

  setup do
    FakeTelegram.setup_fake(&start_supervised!/1)
    Ecto.Adapters.SQL.Sandbox.mode(ChennaiAssist.Repo, {:shared, self()})
    {:ok, _} = Settings.put("telegram_chat_id", "4242")

    {:ok, conv} =
      Chat.start_conversation(%{
        "visitor_name" => "Ravi",
        "visitor_email" => "r@example.com",
        "message" => "Where should I stay?"
      })

    # Drain the alert for the visitor's first message.
    assert_receive {:telegram, _, "sendMessage", %{"text" => alert}}
    %{conv: conv, alert: alert}
  end

  defp update(text, opts \\ []) do
    message =
      %{
        "message_id" => 77,
        "chat" => %{"id" => Keyword.get(opts, :chat_id, 4242), "type" => "private"},
        "text" => text
      }
      |> then(fn m ->
        if q = opts[:quoting], do: Map.put(m, "reply_to_message", %{"text" => q}), else: m
      end)

    %{"update_id" => 1, "message" => message}
  end

  defp post_update(conn, body, secret \\ Telegram.webhook_secret()) do
    conn
    |> put_req_header("x-telegram-bot-api-secret-token", secret)
    |> post(~p"/telegram/webhook", body)
  end

  test "a reply to a chat alert is posted to the visitor's chat", %{conn: conn, conv: conv, alert: alert} do
    Chat.subscribe(conv)
    conn = post_update(conn, update("Try Velachery or Adyar.", quoting: alert))

    assert response(conn, 200)
    assert_receive {:new_message, %{sender: "admin", body: "Try Velachery or Adyar."}}
    assert_receive {:telegram, _, "sendMessage", %{"text" => "✓ Sent to Ravi", "reply_parameters" => %{"message_id" => 77}}}
    refute Chat.get_conversation!(conv.id).unread_by_admin
  end

  test "a reply to a question alert saves and returns the answer", %{conn: conn} do
    {:ok, q} =
      HelpDesk.ask_question(%{
        "name" => "Meena",
        "email" => "m@example.com",
        "category" => "food",
        "body" => "Best filter coffee near Mylapore?"
      })

    assert_receive {:telegram, _, "sendMessage", %{"text" => q_alert}}

    post_update(conn, update("Try the shops on North Mada Street.", quoting: q_alert))

    q = HelpDesk.get_question!(q.id)
    assert q.answer == "Try the shops on North Mada Street."
    refute q.public
    assert_receive {:telegram, _, "sendMessage", %{"text" => "✓ Answer saved and emailed to Meena" <> _}}
  end

  test "rejects requests without the secret", %{conn: conn, conv: conv, alert: alert} do
    post_update(conn, update("hacked", quoting: alert), "wrong-secret")
    assert [%{sender: "visitor"}] = Chat.list_messages(conv)
    refute_receive {:telegram, _, "sendMessage", _}, 200
  end

  test "ignores messages from anyone but the linked admin", %{conn: conn, conv: conv, alert: alert} do
    post_update(conn, update("hi from a stranger", quoting: alert, chat_id: 999))
    assert [%{sender: "visitor"}] = Chat.list_messages(conv)
    refute_receive {:telegram, _, "sendMessage", _}, 200
  end

  test "a message that is not a reply gets a hint", %{conn: conn, conv: conv} do
    post_update(conn, update("hello?"))
    assert [%{sender: "visitor"}] = Chat.list_messages(conv)
    assert_receive {:telegram, _, "sendMessage", %{"text" => "To answer someone, swipe-reply" <> _}}
  end
end
