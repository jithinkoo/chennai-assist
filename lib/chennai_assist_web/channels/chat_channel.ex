defmodule ChennaiAssistWeb.ChatChannel do
  @moduledoc """
  Live updates for one chat in the mobile app. Joining needs the chat's secret
  token (the topic is "chat:<token>"). Pushes:
    * "new_message"  - %{id, sender, body, sent_at}
    * "status"       - %{status: "open" | "closed"}
  The app can also send a message with the "send" event (%{"body" => text}).
  """
  use Phoenix.Channel

  alias ChennaiAssist.Chat
  alias ChennaiAssistWeb.API.ApiJSON

  @impl true
  def join("chat:" <> token, _payload, socket) do
    case Chat.get_conversation_by_token(token) do
      nil ->
        {:error, %{reason: "not_found"}}

      conv ->
        Chat.subscribe(conv)
        {:ok, %{status: conv.status}, assign(socket, :conversation_id, conv.id)}
    end
  end

  @impl true
  def handle_in("send", %{"body" => body}, socket) do
    conv = Chat.get_conversation!(socket.assigns.conversation_id)

    case Chat.send_message(conv, "visitor", body) do
      {:ok, msg} -> {:reply, {:ok, ApiJSON.message(msg)}, socket}
      {:error, changeset} -> {:reply, {:error, %{errors: ApiJSON.errors(changeset)}}, socket}
    end
  end

  @impl true
  def handle_info({:new_message, msg}, socket) do
    push(socket, "new_message", ApiJSON.message(msg))
    {:noreply, socket}
  end

  def handle_info({:conversation_updated, conv}, socket) do
    push(socket, "status", %{status: conv.status})
    {:noreply, socket}
  end

  def handle_info(_other, socket), do: {:noreply, socket}
end
