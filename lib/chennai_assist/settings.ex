defmodule ChennaiAssist.Settings do
  @moduledoc """
  Small key/value store for settings the admin changes from the website
  (e.g. which Telegram chat receives alerts), so no redeploy is needed.
  """
  alias ChennaiAssist.Repo

  defmodule Setting do
    @moduledoc false
    use Ecto.Schema

    schema "settings" do
      field :key, :string
      field :value, :string
      timestamps(type: :utc_datetime)
    end
  end

  def get(key) when is_binary(key) do
    case Repo.get_by(Setting, key: key) do
      %Setting{value: value} -> value
      nil -> nil
    end
  end

  def put(key, value) when is_binary(key) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert(
      %Setting{key: key, value: value && to_string(value), inserted_at: now, updated_at: now},
      on_conflict: [set: [value: value && to_string(value), updated_at: now]],
      conflict_target: :key
    )
  end
end
