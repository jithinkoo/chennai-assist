defmodule ChennaiAssist.Repo do
  use Ecto.Repo,
    otp_app: :chennai_assist,
    adapter: Ecto.Adapters.Postgres
end
