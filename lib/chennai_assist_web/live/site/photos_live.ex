defmodule ChennaiAssistWeb.Site.PhotosLive do
  use ChennaiAssistWeb, :live_view

  alias ChennaiAssist.Gallery

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Chennai in photos")
     |> assign(:photos, Gallery.list_photos())
     |> assign(:open, nil)}
  end

  @impl true
  def handle_event("open", %{"id" => id}, socket) do
    {:noreply, assign(socket, :open, Enum.find(socket.assigns.photos, &(to_string(&1.id) == id)))}
  end

  def handle_event("close", _, socket), do: {:noreply, assign(socket, :open, nil)}

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold text-zinc-900">Chennai in photos</h1>
    <p class="mt-2 text-zinc-600">Streets, beaches, temples, food and everyday life in Chennai.</p>

    <p :if={@photos == []} class="mt-10 text-zinc-500">Photos are coming soon.</p>

    <div class="mt-6 columns-1 sm:columns-2 lg:columns-3 gap-4 [&>*]:mb-4">
      <figure
        :for={photo <- @photos}
        class="break-inside-avoid overflow-hidden rounded-2xl bg-white border border-zinc-200 cursor-zoom-in"
        phx-click="open"
        phx-value-id={photo.id}
      >
        <img src={photo.image_url} alt={photo.caption} class="w-full" loading="lazy" />
        <figcaption class="p-3 text-sm">
          {photo.caption}<span :if={photo.area} class="text-zinc-500"> · {photo.area}</span>
        </figcaption>
      </figure>
    </div>

    <div
      :if={@open}
      class="fixed inset-0 z-50 bg-black/85 flex items-center justify-center p-4"
      phx-click="close"
      phx-window-keydown="close"
      phx-key="Escape"
    >
      <figure class="max-w-5xl">
        <img src={@open.image_url} alt={@open.caption} class="max-h-[80vh] mx-auto rounded-lg" />
        <figcaption class="mt-3 text-center text-white">
          {@open.caption}<span :if={@open.area} class="opacity-70"> · {@open.area}</span>
        </figcaption>
      </figure>
    </div>
    """
  end
end
