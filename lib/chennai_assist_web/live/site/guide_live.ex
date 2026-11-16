defmodule ChennaiAssistWeb.Site.GuideLive do
  use ChennaiAssistWeb, :live_view
  import ChennaiAssistWeb.SiteComponents

  alias ChennaiAssist.Content
  alias ChennaiAssist.Content.Guide

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(%{"slug" => slug}, _url, socket) do
    guide = Content.get_published_guide_by_slug!(slug)

    {:noreply,
     socket
     |> assign(:page_title, guide.title)
     |> assign(:guide, guide)
     |> assign(:related, Content.list_published_guides(guide.category) |> Enum.reject(&(&1.id == guide.id)))}
  end

  def handle_params(params, _url, socket) do
    category = if params["category"] in Guide.categories(), do: params["category"]

    {:noreply,
     socket
     |> assign(:page_title, "City guide")
     |> assign(:category, category)
     |> assign(:categories, Guide.categories())
     |> assign(:guides, Content.list_published_guides(category))}
  end

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <article class="mx-auto max-w-3xl">
      <.link navigate={~p"/guide?category=#{@guide.category}"} class="text-sm text-brand">
        ← {category_icon(@guide.category)} {category_label(@guide.category)}
      </.link>
      <h1 class="mt-3 text-3xl sm:text-4xl font-bold text-zinc-900">{@guide.title}</h1>
      <p class="mt-3 text-lg text-zinc-600">{@guide.summary}</p>
      <div class="mt-8 rounded-2xl bg-white p-6 sm:p-8 border border-zinc-200">
        <.prose text={@guide.body} />
      </div>
      <div class="mt-8 rounded-2xl bg-sea/10 p-6">
        <p class="font-semibold text-zinc-900">Still have a question about this?</p>
        <p class="mt-1 text-zinc-700">Talk to a real person who knows Chennai.</p>
        <div class="mt-4 flex gap-3">
          <.link navigate={~p"/chat"} class="rounded-full bg-brand px-5 py-2 text-white font-semibold">
            Live chat
          </.link>
          <.link navigate={~p"/ask"} class="rounded-full bg-white px-5 py-2 font-semibold border">
            Ask a question
          </.link>
        </div>
      </div>
      <div :if={@related != []} class="mt-8">
        <h2 class="font-semibold text-zinc-900">More on {category_label(@guide.category)}</h2>
        <ul class="mt-2 list-disc pl-6">
          <li :for={g <- @related}>
            <.link navigate={~p"/guide/#{g.slug}"} class="text-brand hover:underline">{g.title}</.link>
          </li>
        </ul>
      </div>
    </article>
    """
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold text-zinc-900">Chennai city guide</h1>
    <p class="mt-2 text-zinc-600">Practical, honest notes for newcomers and visitors.</p>

    <div class="mt-6 flex flex-wrap gap-2">
      <.link
        patch={~p"/guide"}
        class={["rounded-full px-4 py-1.5 text-sm border", is_nil(@category) && "bg-zinc-900 text-white"]}
      >
        All
      </.link>
      <.link
        :for={cat <- @categories}
        patch={~p"/guide?category=#{cat}"}
        class={["rounded-full px-4 py-1.5 text-sm border bg-white", @category == cat && "!bg-zinc-900 text-white"]}
      >
        {category_icon(cat)} {category_label(cat)}
      </.link>
    </div>

    <p :if={@guides == []} class="mt-10 text-zinc-500">
      Nothing here yet. <.link navigate={~p"/ask"} class="text-brand">Ask us about it</.link>
      and we will write it up.
    </p>

    <div class="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <.link
        :for={g <- @guides}
        navigate={~p"/guide/#{g.slug}"}
        class="rounded-2xl bg-white p-5 border border-zinc-200 hover:border-brand hover:shadow-sm"
      >
        <p class="text-xs text-zinc-500">{category_icon(g.category)} {category_label(g.category)}</p>
        <h2 class="mt-2 text-lg font-semibold text-zinc-900">{g.title}</h2>
        <p class="mt-2 text-sm text-zinc-600">{g.summary}</p>
      </.link>
    </div>
    """
  end
end
