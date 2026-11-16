defmodule ChennaiAssistWeb.Site.HomeLive do
  use ChennaiAssistWeb, :live_view
  import ChennaiAssistWeb.SiteComponents

  alias ChennaiAssist.{Content, Gallery, HelpDesk}
  alias ChennaiAssist.Content.Guide

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Your Chennai help desk")
     |> assign(:photos, Gallery.list_photos(limit: 6))
     |> assign(:answers, HelpDesk.list_public_answers() |> Enum.take(3))
     |> assign(:interviews, Content.list_published_interviews() |> Enum.take(3))
     |> assign(:categories, Guide.categories())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="rounded-3xl bg-gradient-to-br from-sea to-teal-700 text-white px-6 py-12 sm:px-12 sm:py-16">
      <p class="text-sm uppercase tracking-widest text-teal-100">Vanakkam! Welcome to Chennai</p>
      <h1 class="mt-3 text-3xl sm:text-5xl font-bold leading-tight max-w-3xl">
        Moving to, living in or visiting Chennai? Ask us anything.
      </h1>
      <p class="mt-4 max-w-2xl text-teal-50 text-lg">
        Rent and areas, autos, weather, food, culture, politics, people. Your personal Chennai
        help desk, with a real person answering.
      </p>
      <div class="mt-8 flex flex-wrap gap-3">
        <.link
          navigate={~p"/chat"}
          class="rounded-full bg-brand px-6 py-3 font-semibold hover:bg-orange-800"
        >
          Start a live chat
        </.link>
        <.link
          navigate={~p"/ask"}
          class="rounded-full bg-white/15 px-6 py-3 font-semibold hover:bg-white/25"
        >
          Ask a question
        </.link>
      </div>
    </section>

    <section class="mt-12">
      <h2 class="text-2xl font-bold text-zinc-900">Explore the city guide</h2>
      <div class="mt-5 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
        <.link
          :for={cat <- @categories}
          navigate={~p"/guide?category=#{cat}"}
          class="rounded-2xl bg-white p-4 border border-zinc-200 hover:border-brand hover:shadow-sm"
        >
          <span class="text-2xl">{category_icon(cat)}</span>
          <span class="mt-2 block font-semibold text-zinc-900">{category_label(cat)}</span>
        </.link>
      </div>
    </section>

    <section :if={@photos != []} class="mt-12">
      <div class="flex items-baseline justify-between">
        <h2 class="text-2xl font-bold text-zinc-900">Chennai in photos</h2>
        <.link navigate={~p"/photos"} class="text-brand font-semibold">See all →</.link>
      </div>
      <div class="mt-5 grid grid-cols-2 md:grid-cols-3 gap-3">
        <figure :for={photo <- @photos} class="overflow-hidden rounded-2xl bg-white">
          <img src={photo.image_url} alt={photo.caption} class="h-48 w-full object-cover" loading="lazy" />
          <figcaption class="p-3 text-sm">
            {photo.caption}<span :if={photo.area} class="text-zinc-500"> · {photo.area}</span>
          </figcaption>
        </figure>
      </div>
    </section>

    <section class="mt-12 grid gap-6 lg:grid-cols-2">
      <div>
        <h2 class="text-2xl font-bold text-zinc-900">Recently answered</h2>
        <p :if={@answers == []} class="mt-4 text-zinc-500">
          No public answers yet. <.link navigate={~p"/ask"} class="text-brand">Be the first to ask.</.link>
        </p>
        <div :for={q <- @answers} class="mt-4 rounded-2xl bg-white p-5 border border-zinc-200">
          <p class="text-xs text-zinc-500">{category_label(q.category)}</p>
          <p class="mt-1 font-semibold text-zinc-900">{q.body}</p>
          <p class="mt-2 text-zinc-700 line-clamp-3">{q.answer}</p>
        </div>
      </div>
      <div>
        <h2 class="text-2xl font-bold text-zinc-900">Local voices</h2>
        <p :if={@interviews == []} class="mt-4 text-zinc-500">
          Interviews with local people about their neighbourhoods are coming soon.
        </p>
        <.link
          :for={i <- @interviews}
          navigate={~p"/interviews/#{i.slug}"}
          class="mt-4 flex gap-4 rounded-2xl bg-white p-4 border border-zinc-200 hover:border-brand"
        >
          <img :if={i.photo_url} src={i.photo_url} alt="" class="h-20 w-20 rounded-xl object-cover" />
          <div>
            <p class="font-semibold text-zinc-900">{i.title}</p>
            <p class="text-sm text-zinc-500">{i.person_name} · {i.area}</p>
          </div>
        </.link>
      </div>
    </section>
    """
  end
end
