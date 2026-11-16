defmodule ChennaiAssist.Gallery do
  @moduledoc "Photographs of Chennai uploaded by the admin."
  import Ecto.Query, warn: false

  alias ChennaiAssist.Repo
  alias ChennaiAssist.Gallery.Photo

  @doc "Directory uploaded files are written to; served at /uploads."
  def uploads_dir do
    Application.get_env(:chennai_assist, :uploads_dir) ||
      Path.join([:code.priv_dir(:chennai_assist), "static", "uploads"])
  end

  def list_photos(opts \\ []) do
    Photo
    |> order_by(desc: :inserted_at, desc: :id)
    |> then(fn q -> if l = opts[:limit], do: limit(q, ^l), else: q end)
    |> Repo.all()
  end

  def get_photo!(id), do: Repo.get!(Photo, id)

  def change_photo(%Photo{} = photo, attrs \\ %{}), do: Photo.changeset(photo, attrs)

  def create_photo(attrs), do: %Photo{} |> Photo.changeset(attrs) |> Repo.insert()

  def update_photo(%Photo{} = photo, attrs), do: photo |> Photo.changeset(attrs) |> Repo.update()

  @doc "Deletes the record and, for local uploads, the file."
  def delete_photo(%Photo{} = photo) do
    with {:ok, photo} <- Repo.delete(photo) do
      case photo.image_url do
        "/uploads/" <> file -> File.rm(Path.join(uploads_dir(), Path.basename(file)))
        _ -> :ok
      end

      {:ok, photo}
    end
  end
end
