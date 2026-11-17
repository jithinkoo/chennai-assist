defmodule ChennaiAssistWeb.Site.ChatLive do
  @moduledoc """
  Visitor side of the live help-desk chat.

  `/chat` asks for name and email and creates a conversation. `/chat/:token`
  is the private chat page; the token is emailed to the visitor so they can
  come back later.
  """
  use ChennaiAssistWeb, :live_view

  alias ChennaiAssist.{Chat, Notifier}

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(%{"token" => token}, _url, socket) do
    case Chat.get_conversation_by_token(token) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "That chat link is not valid. Start a new chat below.")
         |> push_navigate(to: ~p"/chat")}

      conversation ->
        if connected?(socket), do: Chat.subscribe(conversation)

        {:noreply,
         socket
         |> assign(:page_title, "Live chat")
         |> assign(:conversation, conversation)
         |> stream(:messages, Chat.list_messages(conversation), reset: true)
         |> assign_message_form()}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Start a live chat")
     |> assign(:start_form, to_form(Chat.change_start(), as: :start))}
  end

  @impl true
  def handle_event("validate_start", %{"start" => params}, socket) do
    form = params |> Chat.change_start() |> Map.put(:action, :validate) |> to_form(as: :start)
    {:noreply, assign(socket, :start_form, form)}
  end

  def handle_event("start", %{"start" => params}, socket) do
    case Chat.start_conversation(params) do
      {:ok, conversation} ->
        Notifier.chat_started(conversation, url(~p"/chat/#{conversation.token}"))
        {:noreply, push_patch(socket, to: ~p"/chat/#{conversation.token}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :start_form, to_form(changeset, as: :start))}
    end
  end

  def handle_event("send", %{"message" => %{"body" => body}}, socket) do
    case Chat.send_message(socket.assigns.conversation, "visitor", body) do
      {:ok, _message} -> {:noreply, assign_message_form(socket)}
      {:error, _changeset} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info({:conversation_updated, conversation}, socket) do
    {:noreply, assign(socket, :conversation, conversation)}
  end

  # Ignore anything else (e.g. mail-adapter notifications in tests).
  def handle_info(_other, socket), do: {:noreply, socket}

  defp assign_message_form(socket) do
    assign(socket, :message_form, to_form(%{"body" => ""}, as: :message))
  end

  @impl true
  def render(%{live_action: :chat} = assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-zinc-900">Live chat</h1>
          <p class="text-sm text-zinc-500">
            Hi {@conversation.visitor_name}. We reply here in real time when we are online, and
            your private chat link was emailed to {@conversation.visitor_email}.
          </p>
        </div>
        <span class={[
          "rounded-full px-3 py-1 text-xs font-semibold",
          @conversation.status == "open" && "bg-emerald-100 text-emerald-800",
          @conversation.status == "closed" && "bg-zinc-200 text-zinc-700"
        ]}>
          {if @conversation.status == "open", do: "Open", else: "Closed"}
        </span>
      </div>

      <div
        id="messages"
        phx-update="stream"
        phx-hook="ScrollBottom"
        class="mt-4 h-[55vh] overflow-y-auto rounded-2xl bg-white border border-zinc-200 p-4 space-y-3"
      >
        <div id="welcome" class="text-sm text-zinc-500 text-center">
          Vanakkam! Ask anything about Chennai: rent, areas, autos, food, culture...
        </div>
        <div
          :for={{id, msg} <- @streams.messages}
          id={id}
          class={["flex", msg.sender == "visitor" && "justify-end"]}
        >
          <div class={[
            "max-w-[80%] rounded-2xl px-4 py-2",
            msg.sender == "visitor" && "bg-brand text-white rounded-br-sm",
            msg.sender == "admin" && "bg-sea/10 text-zinc-900 rounded-bl-sm"
          ]}>
            <p :if={msg.sender == "admin"} class="text-xs font-semibold text-sea">Chennai Assist</p>
            <p class="whitespace-pre-line">{msg.body}</p>
            <p class="mt-1 text-[10px] opacity-60">{Calendar.strftime(msg.inserted_at, "%d %b, %H:%M UTC")}</p>
          </div>
        </div>
      </div>

      <.form
        for={@message_form}
        id="message-form"
        phx-submit="send"
        phx-hook="ClearOnSubmit"
        class="mt-3 flex gap-2"
      >
        <input
          type="text"
          name={@message_form[:body].name}
          value={@message_form[:body].value}
          placeholder="Type your message..."
          autocomplete="off"
          maxlength="2000"
          class="flex-1 rounded-full border-zinc-300 px-4 focus:border-brand focus:ring-brand"
          required
        />
        <button class="rounded-full bg-brand px-6 py-2 text-white font-semibold hover:bg-orange-800">
          Send
        </button>
      </.form>
      <p class="mt-3 text-xs text-zinc-500">
        Keep this page's link private: anyone with it can read this chat.
      </p>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-lg">
      <h1 class="text-3xl font-bold text-zinc-900">Chat with a Chennai local</h1>
      <p class="mt-2 text-zinc-600">
        Your personal assistant for anything Chennai: travel, apartments, moving, weather, food,
        areas, culture. Tell us who you are and we will reply here in real time, and by email if
        you have left.
      </p>
      <div class="mt-6 rounded-2xl bg-white p-6 border border-zinc-200">
        <.simple_form for={@start_form} id="start-chat" phx-change="validate_start" phx-submit="start">
          <.input field={@start_form[:visitor_name]} type="text" label="Your name" required />
          <.input field={@start_form[:visitor_email]} type="email" label="Your email" required />
          <.input
            field={@start_form[:message]}
            type="textarea"
            label="How can we help? (optional)"
            placeholder="e.g. I'm joining a company in Guindy next month. Where should I stay?"
          />
          <:actions>
            <.button phx-disable-with="Starting..." class="w-full">Start chat</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
