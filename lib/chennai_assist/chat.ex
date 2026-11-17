defmodule ChennaiAssist.Chat do
  @moduledoc """
  Real-time help-desk chat between website visitors and the admin.

  A visitor starts a conversation with their name and email and gets a secret
  token; the chat page lives at `/chat/:token`. Messages are broadcast over
  Phoenix.PubSub so both sides see them instantly.
  """
  import Ecto.Query, warn: false

  alias ChennaiAssist.{Alerts, Repo}
  alias ChennaiAssist.Chat.{Conversation, Message}

  @pubsub ChennaiAssist.PubSub
  @admin_topic "chat:admin"

  ## PubSub

  def subscribe_admin, do: Phoenix.PubSub.subscribe(@pubsub, @admin_topic)

  def subscribe(%Conversation{id: id}),
    do: Phoenix.PubSub.subscribe(@pubsub, conversation_topic(id))

  defp conversation_topic(id), do: "chat:conversation:#{id}"

  defp broadcast_admin(message), do: Phoenix.PubSub.broadcast(@pubsub, @admin_topic, message)

  ## Conversations

  def change_start(attrs \\ %{}), do: Conversation.start_changeset(%Conversation{}, attrs)

  @doc """
  Starts a conversation. An optional first message (`"message"` in attrs) is
  saved straight away. The admin is alerted once either way.
  """
  def start_conversation(attrs) do
    token = :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)

    %Conversation{token: token, last_message_at: now(), unread_by_admin: true}
    |> Conversation.start_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, conv} ->
        broadcast_admin({:conversation_updated, conv})
        first = String.trim(attrs["message"] || attrs[:message] || "")

        # A first message alerts through send_message/3; otherwise alert here.
        if first == "" or match?({:error, _}, send_message(conv, "visitor", first)),
          do: Alerts.chat_started(conv)

        {:ok, conv}

      error ->
        error
    end
  end

  def get_conversation_by_token(token) when is_binary(token),
    do: Repo.get_by(Conversation, token: token)

  def get_conversation!(id), do: Repo.get!(Conversation, id)

  def list_conversations do
    from(c in Conversation, order_by: [desc: c.last_message_at, desc: c.id], limit: 200)
    |> Repo.all()
  end

  def count_unread do
    from(c in Conversation, where: c.unread_by_admin) |> Repo.aggregate(:count)
  end

  def mark_read(%Conversation{unread_by_admin: false} = conv), do: {:ok, conv}

  def mark_read(%Conversation{} = conv) do
    conv
    |> Conversation.status_changeset(%{unread_by_admin: false})
    |> Repo.update()
    |> tap(fn
      {:ok, conv} -> broadcast_admin({:conversation_updated, conv})
      _ -> :ok
    end)
  end

  def set_status(%Conversation{} = conv, status) when status in ~w(open closed) do
    conv
    |> Conversation.status_changeset(%{status: status})
    |> Repo.update()
    |> tap(fn
      {:ok, conv} ->
        broadcast_admin({:conversation_updated, conv})
        Phoenix.PubSub.broadcast(@pubsub, conversation_topic(conv.id), {:conversation_updated, conv})

      _ ->
        :ok
    end)
  end

  ## Messages

  def list_messages(%Conversation{id: id}) do
    from(m in Message, where: m.conversation_id == ^id, order_by: [asc: m.id])
    |> Repo.all()
  end

  def change_message(attrs \\ %{}), do: Message.changeset(%Message{}, attrs)

  @doc """
  Saves a message from `sender` ("visitor" or "admin") and broadcasts it.
  A visitor message re-opens a closed conversation and marks it unread.
  """
  def send_message(%Conversation{} = conv, sender, body) do
    result =
      Repo.transaction(fn ->
        with {:ok, msg} <-
               conv
               |> Ecto.build_assoc(:messages)
               |> Message.changeset(%{sender: sender, body: String.trim(body || "")})
               |> Repo.insert(),
             {:ok, conv} <-
               conv
               |> Conversation.status_changeset(conversation_changes(conv, sender))
               |> Repo.update() do
          {msg, conv}
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, {msg, conv}} ->
        Phoenix.PubSub.broadcast(@pubsub, conversation_topic(conv.id), {:new_message, msg})
        broadcast_admin({:conversation_updated, conv})
        if sender == "visitor", do: Alerts.visitor_message(conv, msg)
        {:ok, msg}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp conversation_changes(_conv, "visitor"),
    do: %{last_message_at: now(), unread_by_admin: true, status: "open"}

  defp conversation_changes(conv, _admin),
    do: %{last_message_at: now(), unread_by_admin: false, status: conv.status}

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)
end
