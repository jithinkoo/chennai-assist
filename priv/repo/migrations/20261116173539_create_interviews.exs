defmodule ChennaiAssist.Repo.Migrations.CreateInterviews do
  use Ecto.Migration

  def change do
    create table(:interviews) do
      add :title, :string
      add :slug, :string
      add :person_name, :string
      add :occupation, :string
      add :area, :string
      add :body, :text
      add :photo_url, :string
      add :published, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:interviews, [:slug])
  end
end
