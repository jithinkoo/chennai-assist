defmodule ChennaiAssist.Gallery.Photo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "photos" do
    field :area, :string
    field :caption, :string
    field :image_url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(photo, attrs) do
    photo
    |> cast(attrs, [:caption, :area, :image_url])
    |> validate_required([:caption, :image_url])
    |> validate_length(:caption, max: 280)
  end
end
