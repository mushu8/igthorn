defmodule UiWeb.PageControllerTest do
  use UiWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Igthorn"
  end
end
