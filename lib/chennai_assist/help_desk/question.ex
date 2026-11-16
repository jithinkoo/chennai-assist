defmodule ChennaiAssist.HelpDesk.Question do
  use Ecto.Schema
  import Ecto.Changeset

  @categories ~w(moving rent transport weather food culture people politics areas jobs other)

  schema "questions" do
    field :answer, :string
    field :answered_at, :utc_datetime
    field :body, :string
    field :category, :string
    field :email, :string
    field :name, :string
    field :public, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def categories, do: @categories

  @doc "Changeset for a visitor asking a question."
  def ask_changeset(question, attrs) do
    question
    |> cast(attrs, [:name, :email, :category, :body])
    |> validate_required([:name, :email, :category, :body])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "enter a valid email")
    |> validate_inclusion(:category, @categories)
    |> validate_length(:name, max: 80)
    |> validate_length(:body, min: 10, max: 3000)
  end

  @doc "Changeset for the admin answering a question."
  def answer_changeset(question, attrs) do
    question
    |> cast(attrs, [:answer, :public])
    |> validate_required([:answer])
    |> put_change(:answered_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
