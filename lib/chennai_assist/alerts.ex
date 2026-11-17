defmodule ChennaiAssist.Alerts do
  @moduledoc """
  "Someone needs a reply" alerts for the admin: a Telegram message to the
  phone, and a PubSub event that open admin pages turn into a sound and a
  browser notification.
  """
  alias ChennaiAssist.Telegram

  @pubsub ChennaiAssist.PubSub
  @topic "admin:alerts"

  def subscribe, do: Phoenix.PubSub.subscribe(@pubsub, @topic)

  # Each Telegram alert ends with a reference such as "Chat #12" or
  # "Question #5". When the admin swipe-replies in Telegram, the webhook reads
  # it back from the quoted alert to know where the reply belongs.
  @ref ~r/\b(Chat|Question) #(\d+)\b/

  @doc "Finds the chat or question an alert's text refers to."
  def parse_reference(text) when is_binary(text) do
    case Regex.scan(@ref, text) |> List.last() do
      [_, "Chat", id] -> {:chat, String.to_integer(id)}
      [_, "Question", id] -> {:question, String.to_integer(id)}
      nil -> :none
    end
  end

  def parse_reference(_), do: :none

  def chat_started(conversation) do
    dispatch(
      "👋 New chat from #{conversation.visitor_name} (#{conversation.visitor_email})\nChat ##{conversation.id}",
      "New chat: #{conversation.visitor_name}",
      "Started a chat",
      "/admin/chats/#{conversation.id}"
    )
  end

  def visitor_message(conversation, message) do
    dispatch(
      "💬 #{conversation.visitor_name}: #{truncate(message.body, 500)}\nChat ##{conversation.id}",
      "Chat: #{conversation.visitor_name}",
      truncate(message.body, 140),
      "/admin/chats/#{conversation.id}"
    )
  end

  def question_asked(question) do
    dispatch(
      "❓ New question from #{question.name} (#{question.category}): #{truncate(question.body, 500)}\nQuestion ##{question.id}",
      "New question: #{question.name}",
      truncate(question.body, 140),
      "/admin/questions"
    )
  end

  defp dispatch(telegram_text, title, body, path) do
    Telegram.notify(
      "#{telegram_text}\n\n↩️ Swipe-reply to answer here, or open: #{ChennaiAssistWeb.Endpoint.url()}#{path}"
    )

    Phoenix.PubSub.broadcast(@pubsub, @topic, {:admin_alert, %{title: title, body: body, url: path}})
    :ok
  end

  defp truncate(text, max) do
    if String.length(text) > max, do: String.slice(text, 0, max - 1) <> "…", else: text
  end
end
