defmodule ChennaiAssistWeb.Admin.DashboardLive do
  use ChennaiAssistWeb, :live_view

  alias ChennaiAssist.{Chat, Content, Gallery, HelpDesk}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Chat.subscribe_admin()
      HelpDesk.subscribe_admin()
    end

    {:ok, socket |> assign(:page_title, "Admin") |> load()}
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, load(socket)}

  defp load(socket) do
    assign(socket,
      unread_chats: Chat.count_unread(),
      unanswered: HelpDesk.count_unanswered(),
      guides: length(Content.list_guides()),
      interviews: length(Content.list_interviews()),
      photos: length(Gallery.list_photos())
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold text-zinc-900">Help desk dashboard</h1>
    <p class="mt-1 text-zinc-500">Updates live as visitors chat and ask questions.</p>
    <div class="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <.tile href={~p"/admin/chats"} label="Chats waiting for reply" value={@unread_chats} hot={@unread_chats > 0} />
      <.tile href={~p"/admin/questions"} label="Unanswered questions" value={@unanswered} hot={@unanswered > 0} />
      <.tile href={~p"/admin/guides"} label="City guide articles" value={@guides} />
      <.tile href={~p"/admin/photos"} label="Photos" value={@photos} />
      <.tile href={~p"/admin/interviews"} label="Interviews" value={@interviews} />
    </div>
    """
  end

  attr :href, :string, required: true
  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :hot, :boolean, default: false

  defp tile(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "rounded-2xl p-5 border hover:shadow-sm",
        @hot && "bg-brand text-white border-brand",
        !@hot && "bg-white border-zinc-200"
      ]}
    >
      <p class="text-4xl font-bold">{@value}</p>
      <p class={["mt-1 text-sm", !@hot && "text-zinc-500"]}>{@label}</p>
    </.link>
    """
  end
end
