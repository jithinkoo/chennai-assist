defmodule ChennaiAssist.Content.Guide do
  use Ecto.Schema
  import Ecto.Changeset

  @categories ~w(moving rent transport weather food culture people politics areas jobs)

  schema "guides" do
    field :body, :string
    field :category, :string
    field :published, :boolean, default: false
    field :slug, :string
    field :summary, :string
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  def categories, do: @categories

  @doc false
  def changeset(guide, attrs) do
    guide
    |> cast(attrs, [:title, :slug, :category, :summary, :body, :published])
    |> validate_required([:title, :slug, :category, :summary, :body])
    |> validate_inclusion(:category, @categories)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "use lowercase letters, numbers and dashes")
    |> unique_constraint(:slug)
  end
end
