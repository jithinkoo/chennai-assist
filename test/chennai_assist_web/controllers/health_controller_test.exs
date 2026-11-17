defmodule ChennaiAssistWeb.HealthControllerTest do
  use ChennaiAssistWeb.ConnCase, async: true

  test "GET /health answers ok", %{conn: conn} do
    conn = get(conn, ~p"/health")
    assert response(conn, 200) == "ok"
  end
end
