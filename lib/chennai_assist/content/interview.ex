defmodule ChennaiAssist.Content.Interview do
  use Ecto.Schema
  import Ecto.Changeset

  schema "interviews" do
    field :area, :string
    field :body, :string
    field :occupation, :string
    field :person_name, :string
    field :photo_url, :string
    field :published, :boolean, default: false
    field :slug, :string
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(interview, attrs) do
    interview
    |> cast(attrs, [:title, :slug, :person_name, :occupation, :area, :body, :photo_url, :published])
    |> validate_required([:title, :slug, :person_name, :area, :body])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "use lowercase letters, numbers and dashes")
    |> unique_constraint(:slug)
  end
end
