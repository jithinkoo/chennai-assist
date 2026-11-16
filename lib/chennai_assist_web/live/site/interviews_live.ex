defmodule ChennaiAssistWeb.Site.InterviewsLive do
  use ChennaiAssistWeb, :live_view
  import ChennaiAssistWeb.SiteComponents

  alias ChennaiAssist.Content

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(%{"slug" => slug}, _url, socket) do
    interview = Content.get_published_interview_by_slug!(slug)
    {:noreply, socket |> assign(:page_title, interview.title) |> assign(:interview, interview)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Local voices")
     |> assign(:interviews, Content.list_published_interviews())}
  end

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <article class="mx-auto max-w-3xl">
      <.link navigate={~p"/interviews"} class="text-sm text-brand">← All interviews</.link>
      <h1 class="mt-3 text-3xl sm:text-4xl font-bold text-zinc-900">{@interview.title}</h1>
      <p class="mt-2 text-zinc-600">
        {@interview.person_name}<span :if={@interview.occupation}>, {@interview.occupation}</span>
        · {@interview.area}
      </p>
      <img
        :if={@interview.photo_url}
        src={@interview.photo_url}
        alt={@interview.person_name}
        class="mt-6 w-full rounded-2xl object-cover max-h-[28rem]"
      />
      <div class="mt-8 rounded-2xl bg-white p-6 sm:p-8 border border-zinc-200">
        <.prose text={@interview.body} />
      </div>
    </article>
    """
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold text-zinc-900">Local voices</h1>
    <p class="mt-2 text-zinc-600">
      Conversations with people who live and work in Chennai about their neighbourhood.
    </p>
    <p :if={@interviews == []} class="mt-10 text-zinc-500">Interviews are coming soon.</p>
    <div class="mt-6 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
      <.link
        :for={i <- @interviews}
        navigate={~p"/interviews/#{i.slug}"}
        class="overflow-hidden rounded-2xl bg-white border border-zinc-200 hover:border-brand"
      >
        <img :if={i.photo_url} src={i.photo_url} alt="" class="h-48 w-full object-cover" />
        <div class="p-5">
          <p class="text-xs text-zinc-500">{i.area}</p>
          <h2 class="mt-1 font-semibold text-zinc-900">{i.title}</h2>
          <p class="mt-1 text-sm text-zinc-600">{i.person_name}</p>
        </div>
      </.link>
    </div>
    """
  end
end
