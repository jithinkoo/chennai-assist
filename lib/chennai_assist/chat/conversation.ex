defmodule ChennaiAssist.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :last_message_at, :utc_datetime
    field :status, :string, default: "open"
    field :token, :string
    field :visitor_email, :string
    field :visitor_name, :string
    field :unread_by_admin, :boolean, default: false

    has_many :messages, ChennaiAssist.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc "Changeset for a visitor starting a chat."
  def start_changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:visitor_name, :visitor_email])
    |> validate_required([:visitor_name, :visitor_email])
    |> validate_format(:visitor_email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "enter a valid email")
    |> validate_length(:visitor_name, max: 80)
  end

  def status_changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:status, :unread_by_admin, :last_message_at])
    |> validate_inclusion(:status, ~w(open closed))
  end
end
