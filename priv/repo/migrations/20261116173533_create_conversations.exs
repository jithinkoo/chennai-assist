defmodule ChennaiAssist.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :visitor_name, :string, null: false
      add :visitor_email, :string, null: false
      add :token, :string, null: false
      add :status, :string, null: false, default: "open"
      add :unread_by_admin, :boolean, null: false, default: false
      add :last_message_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:conversations, [:token])
    create index(:conversations, [:last_message_at])
  end
end
