defmodule ChennaiAssist.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :sender, :string, null: false
      add :body, :text, null: false
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id])
  end
end
