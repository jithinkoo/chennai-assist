defmodule ChennaiAssistWeb.TelegramWebhookController do
  @moduledoc """
  Receives the admin's Telegram replies to alerts and posts them to the
  website: a reply to a chat alert goes into that live chat, a reply to a
  question alert becomes the question's answer.

  Only accepted when Telegram sends our secret header AND the message comes
  from the linked admin chat. Always answers 200 so Telegram does not retry.
  """
  use ChennaiAssistWeb, :controller

  require Logger

  alias ChennaiAssist.{Alerts, Chat, HelpDesk, Repo, Telegram}
  alias ChennaiAssist.HelpDesk.Question

  def create(conn, params) do
    if authentic?(conn) do
      handle(params["message"])
    else
      Logger.warning("Telegram webhook: rejected request with a missing or wrong secret")
    end

    send_resp(conn, 200, "ok")
  end

  defp authentic?(conn) do
    Telegram.configured?() and
      Plug.Crypto.secure_compare(
        List.first(get_req_header(conn, "x-telegram-bot-api-secret-token")) || "",
        Telegram.webhook_secret()
      )
  end

  defp handle(%{"chat" => %{"id" => chat_id}, "message_id" => message_id} = message) do
    if to_string(chat_id) == to_string(Telegram.chat_id()) do
      text = String.trim(message["text"] || "")
      quoted = get_in(message, ["reply_to_message", "text"])
      answer(Alerts.parse_reference(quoted), text, chat_id, message_id)
    end

    :ok
  end

  defp handle(_other), do: :ok

  defp answer(_ref, "", chat_id, message_id),
    do: Telegram.reply(chat_id, message_id, "Only text replies can be sent to the website.")

  defp answer(_ref, "/start" <> _, chat_id, message_id),
    do: Telegram.reply(chat_id, message_id, "👋 Alerts are on. Swipe-reply to an alert to answer it.")

  defp answer({:chat, id}, text, chat_id, message_id) do
    case Repo.get(ChennaiAssist.Chat.Conversation, id) do
      nil ->
        Telegram.reply(chat_id, message_id, "⚠️ That chat no longer exists.")

      conv ->
        case Chat.send_message(conv, "admin", text) do
          {:ok, _} ->
            Telegram.reply(chat_id, message_id, "✓ Sent to #{conv.visitor_name}")

          {:error, _} ->
            Telegram.reply(chat_id, message_id, "⚠️ Not sent: messages can be up to 2000 characters.")
        end
    end
  end

  defp answer({:question, id}, text, chat_id, message_id) do
    case Repo.get(Question, id) do
      nil ->
        Telegram.reply(chat_id, message_id, "⚠️ That question no longer exists.")

      question ->
        {:ok, _} = HelpDesk.answer_question(question, %{"answer" => text})

        Telegram.reply(
          chat_id,
          message_id,
          "✓ Answer saved and emailed to #{question.name}. It stays private; tick \"Show on site\" in the admin to publish it."
        )
    end
  end

  defp answer(:none, _text, chat_id, message_id) do
    Telegram.reply(
      chat_id,
      message_id,
      "To answer someone, swipe-reply (or long-press → Reply) on their alert message."
    )
  end
end
