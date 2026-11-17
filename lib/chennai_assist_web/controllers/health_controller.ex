defmodule ChennaiAssistWeb.HealthController do
  @moduledoc "Answers `ok` instantly; used by uptime monitors to keep the site awake."
  use ChennaiAssistWeb, :controller

  def show(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(200, "ok")
  end
end
