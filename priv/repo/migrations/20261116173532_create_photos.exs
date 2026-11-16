defmodule ChennaiAssist.Repo.Migrations.CreatePhotos do
  use Ecto.Migration

  def change do
    create table(:photos) do
      add :caption, :string
      add :area, :string
      add :image_url, :string

      timestamps(type: :utc_datetime)
    end
  end
end
