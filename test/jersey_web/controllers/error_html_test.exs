defmodule JerseyWeb.ErrorHTMLTest do
  use JerseyWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    assert render_to_string(JerseyWeb.ErrorHTML, "404", "html", []) == "Not Found"
  end

  test "renders 500.html" do
    assert render_to_string(JerseyWeb.ErrorHTML, "500", "html", []) == "Internal Server Error"
  end

  test "renders 400.html" do
    assert render_to_string(JerseyWeb.ErrorHTML, "400", "html", []) == "Bad Request"
  end

  test "renders 422.html" do
    assert render_to_string(JerseyWeb.ErrorHTML, "422", "html", []) == "Unprocessable Content"
  end
end
