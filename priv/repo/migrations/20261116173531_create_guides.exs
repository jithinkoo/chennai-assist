defmodule ChennaiAssist.Repo.Migrations.CreateGuides do
  use Ecto.Migration

  def change do
    create table(:guides) do
      add :title, :string
      add :slug, :string
      add :category, :string
      add :summary, :text
      add :body, :text
      add :published, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:guides, [:slug])
  end
end
