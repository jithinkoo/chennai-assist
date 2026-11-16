defmodule ChennaiAssistWeb.Admin.PhotosLive do
  @moduledoc "Upload and manage Chennai photographs."
  use ChennaiAssistWeb, :live_view

  alias ChennaiAssist.Gallery
  alias ChennaiAssist.Gallery.Photo

  @max_size 15_000_000

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Photos")
     |> assign(:photos, Gallery.list_photos())
     |> assign(:form, to_form(Gallery.change_photo(%Photo{})))
     |> allow_upload(:images,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 10,
       max_file_size: @max_size
     )}
  end

  @impl true
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("cancel-upload", %{"ref" => ref}, socket),
    do: {:noreply, cancel_upload(socket, :images, ref)}

  def handle_event("save", %{"photo" => params}, socket) do
    dir = Gallery.uploads_dir()
    File.mkdir_p!(dir)

    urls =
      consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
        ext = entry.client_name |> Path.extname() |> String.downcase()
        name = "#{System.system_time(:millisecond)}-#{entry.ref}#{ext}"
        File.cp!(path, Path.join(dir, name))
        {:ok, "/uploads/#{name}"}
      end)

    if urls == [] do
      {:noreply, put_flash(socket, :error, "Choose at least one photo.")}
    else
      results =
        Enum.map(urls, fn url ->
          Gallery.create_photo(%{caption: params["caption"], area: params["area"], image_url: url})
        end)

      failed = Enum.count(results, &match?({:error, _}, &1))

      {:noreply,
       socket
       |> assign(:photos, Gallery.list_photos())
       |> assign(:form, to_form(Gallery.change_photo(%Photo{})))
       |> put_flash(
         if(failed == 0, do: :info, else: :error),
         if(failed == 0, do: "#{length(urls)} photo(s) posted.", else: "Caption is required.")
       )}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = id |> Gallery.get_photo!() |> Gallery.delete_photo()
    {:noreply, assign(socket, :photos, Gallery.list_photos())}
  end

  defp error_to_string(:too_large), do: "File is too large (max 15 MB)"
  defp error_to_string(:not_accepted), do: "Only JPG, PNG or WEBP"
  defp error_to_string(:too_many_files), do: "Up to 10 photos at a time"

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-2xl font-bold text-zinc-900">Post photos of Chennai</h1>

    <div class="mt-4 rounded-2xl bg-white p-6 border border-zinc-200">
      <.simple_form for={@form} id="photo-form" phx-change="validate" phx-submit="save">
        <div
          class="rounded-xl border-2 border-dashed border-zinc-300 p-6 text-center"
          phx-drop-target={@uploads.images.ref}
        >
          <.live_file_input upload={@uploads.images} class="mx-auto" />
          <p class="mt-2 text-xs text-zinc-500">Drag photos here or choose files. JPG, PNG, WEBP, up to 15 MB, 10 at a time.</p>
        </div>
        <div :for={entry <- @uploads.images.entries} class="flex items-center gap-3">
          <.live_img_preview entry={entry} class="h-16 w-16 rounded object-cover" />
          <span class="text-sm flex-1 truncate">{entry.client_name} ({entry.progress}%)</span>
          <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-sm text-zinc-500">
            Remove
          </button>
          <p :for={err <- upload_errors(@uploads.images, entry)} class="text-sm text-rose-600">
            {error_to_string(err)}
          </p>
        </div>
        <p :for={err <- upload_errors(@uploads.images)} class="text-sm text-rose-600">{error_to_string(err)}</p>
        <.input field={@form[:caption]} type="text" label="Caption" placeholder="Sunrise at Marina Beach" required />
        <.input field={@form[:area]} type="text" label="Area (optional)" placeholder="Mylapore" />
        <:actions>
          <.button phx-disable-with="Uploading...">Post photos</.button>
        </:actions>
      </.simple_form>
    </div>

    <div class="mt-6 grid grid-cols-2 md:grid-cols-4 gap-3">
      <div :for={p <- @photos} class="rounded-xl bg-white border border-zinc-200 overflow-hidden">
        <img src={p.image_url} alt={p.caption} class="h-36 w-full object-cover" />
        <div class="p-2 text-xs">
          <p class="truncate">{p.caption}</p>
          <button phx-click="delete" phx-value-id={p.id} data-confirm="Delete this photo?" class="text-rose-600">
            Delete
          </button>
        </div>
      </div>
    </div>
    """
  end
end
