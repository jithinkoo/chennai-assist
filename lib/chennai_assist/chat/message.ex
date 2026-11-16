defmodule ChennaiAssist.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :body, :string
    field :sender, :string
    belongs_to :conversation, ChennaiAssist.Chat.Conversation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:sender, :body])
    |> validate_required([:sender, :body])
    |> validate_inclusion(:sender, ~w(visitor admin))
    |> validate_length(:body, min: 1, max: 2000)
  end
end
