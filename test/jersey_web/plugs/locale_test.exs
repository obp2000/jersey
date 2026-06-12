defmodule JerseyWeb.Plugs.LocaleTest do
  use JerseyWeb.ConnCase, async: true

  alias JerseyWeb.Plugs.Locale

  describe "call/2" do
    test "sets locale and stores it in session when locale param is valid" do
      conn =
        build_conn()
        |> Map.replace!(:secret_key_base, JerseyWeb.Endpoint.config(:secret_key_base))
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.put_req_header("content-type", "application/x-www-form-urlencoded")
        |> Map.update!(:params, fn _ -> %{"locale" => "ru"} end)

      conn = Locale.call(conn, [])

      assert get_session(conn, :locale) == "ru"
      assert conn.assigns.locale == "ru"
      assert Gettext.get_locale(JerseyWeb.Gettext) == "ru"
    end

    test "uses session locale when params do not include locale" do
      conn =
        build_conn()
        |> Map.replace!(:secret_key_base, JerseyWeb.Endpoint.config(:secret_key_base))
        |> Phoenix.ConnTest.init_test_session(%{locale: "ru"})
        |> Map.update!(:params, fn _ -> %{} end)

      conn = Locale.call(conn, [])

      assert get_session(conn, :locale) == "ru"
      assert conn.assigns.locale == "ru"
      assert Gettext.get_locale(JerseyWeb.Gettext) == "ru"
    end
  end
end
