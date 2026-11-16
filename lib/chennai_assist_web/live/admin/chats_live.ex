defmodule ChennaiAssistWeb.Admin.ChatsLive do
  @moduledoc "Admin inbox for live chats: conversation list plus reply pane."
  use ChennaiAssistWeb, :live_view

  alias ChennaiAssist.Chat

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Chat.subscribe_admin()

    {:ok,
     socket
     |> assign(:page_title, "Chats")
     |> assign(:conversations, Chat.list_conversations())
     |> assign(:conversation, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    previous = socket.assigns.conversation
    conversation = Chat.get_conversation!(id)

    if connected?(socket) do
      if previous && previous.id != conversation.id,
        do: Phoenix.PubSub.unsubscribe(ChennaiAssist.PubSub, "chat:conversation:#{previous.id}")

      if is_nil(previous) or previous.id != conversation.id, do: Chat.subscribe(conversation)
    end

    {:ok, conversation} = if connected?(socket), do: Chat.mark_read(conversation), else: {:ok, conversation}

    {:noreply,
     socket
     |> assign(:conversation, conversation)
     |> assign(:reply_form, to_form(%{"body" => ""}, as: :reply))
     |> stream(:messages, Chat.list_messages(conversation), reset: true)}
  end

  def handle_params(_params, _url, socket), do: {:noreply, assign(socket, :conversation, nil)}

  @impl true
  def handle_event("reply", %{"reply" => %{"body" => body}}, socket) do
    case Chat.send_message(socket.assigns.conversation, "admin", body) do
      {:ok, _} -> {:noreply, assign(socket, :reply_form, to_form(%{"body" => ""}, as: :reply))}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Message could not be sent.")}
    end
  end

  def handle_event("set_status", %{"status" => status}, socket) do
    {:ok, conversation} = Chat.set_status(socket.assigns.conversation, status)
    {:noreply, assign(socket, :conversation, conversation)}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info({:conversation_updated, conv}, socket) do
    socket = assign(socket, :conversations, Chat.list_conversations())
    current = socket.assigns.conversation

    if current && current.id == conv.id do
      # The admin is looking at this chat, so a new visitor message is already read.
      {:ok, conv} = Chat.mark_read(conv)
      {:noreply, assign(socket, :conversation, conv)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-2xl font-bold text-zinc-900">Live chats</h1>
    <div class="mt-4 grid gap-4 lg:grid-cols-3">
      <aside class="rounded-2xl bg-white border border-zinc-200 divide-y max-h-[70vh] overflow-y-auto">
        <p :if={@conversations == []} class="p-4 text-zinc-500 text-sm">No chats yet.</p>
        <.link
          :for={c <- @conversations}
          patch={~p"/admin/chats/#{c.id}"}
          class={[
            "block p-4 hover:bg-zinc-50",
            @conversation && @conversation.id == c.id && "bg-sea/10"
          ]}
        >
          <div class="flex items-center justify-between gap-2">
            <span class="font-semibold text-zinc-900 truncate">{c.visitor_name}</span>
            <span :if={c.unread_by_admin} class="h-2.5 w-2.5 rounded-full bg-brand" title="Unread"></span>
          </div>
          <p class="text-xs text-zinc-500 truncate">{c.visitor_email}</p>
          <p class="text-xs text-zinc-400">
            {c.status} · {c.last_message_at && Calendar.strftime(c.last_message_at, "%d %b %H:%M UTC")}
          </p>
        </.link>
      </aside>

      <section class="lg:col-span-2">
        <div :if={is_nil(@conversation)} class="rounded-2xl bg-white border border-zinc-200 p-10 text-center text-zinc-500">
          Pick a chat on the left. New chats appear instantly.
        </div>

        <div :if={@conversation}>
          <div class="flex flex-wrap items-center justify-between gap-2">
            <div>
              <p class="font-semibold text-zinc-900">{@conversation.visitor_name}</p>
              <a href={"mailto:#{@conversation.visitor_email}"} class="text-sm text-brand">
                {@conversation.visitor_email}
              </a>
            </div>
            <button
              :if={@conversation.status == "open"}
              phx-click="set_status"
              phx-value-status="closed"
              class="rounded-full border px-4 py-1.5 text-sm"
            >
              Mark closed
            </button>
            <button
              :if={@conversation.status == "closed"}
              phx-click="set_status"
              phx-value-status="open"
              class="rounded-full border px-4 py-1.5 text-sm"
            >
              Re-open
            </button>
          </div>

          <div
            id="admin-messages"
            phx-update="stream"
            phx-hook="ScrollBottom"
            class="mt-3 h-[55vh] overflow-y-auto rounded-2xl bg-white border border-zinc-200 p-4 space-y-3"
          >
            <div
              :for={{id, msg} <- @streams.messages}
              id={id}
              class={["flex", msg.sender == "admin" && "justify-end"]}
            >
              <div class={[
                "max-w-[80%] rounded-2xl px-4 py-2",
                msg.sender == "admin" && "bg-sea text-white rounded-br-sm",
                msg.sender == "visitor" && "bg-zinc-100 text-zinc-900 rounded-bl-sm"
              ]}>
                <p class="whitespace-pre-line">{msg.body}</p>
                <p class="mt-1 text-[10px] opacity-60">{Calendar.strftime(msg.inserted_at, "%d %b, %H:%M UTC")}</p>
              </div>
            </div>
          </div>

          <.form
            for={@reply_form}
            id="reply-form"
            phx-submit="reply"
            phx-hook="ClearOnSubmit"
            class="mt-3 flex gap-2"
          >
            <input
              type="text"
              name={@reply_form[:body].name}
              value={@reply_form[:body].value}
              placeholder="Reply..."
              autocomplete="off"
              maxlength="2000"
              class="flex-1 rounded-full border-zinc-300 px-4 focus:border-sea focus:ring-sea"
              required
            />
            <button class="rounded-full bg-sea px-6 py-2 text-white font-semibold">Send</button>
          </.form>
        </div>
      </section>
    </div>
    """
  end
end
