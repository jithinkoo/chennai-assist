defmodule ChennaiAssist.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add :name, :string
      add :email, :string
      add :category, :string
      add :body, :text
      add :answer, :text
      add :answered_at, :utc_datetime
      add :public, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
