defmodule JerseyWeb.CityLiveTest do
  use JerseyWeb.ConnCase
  import Phoenix.LiveViewTest
  import Jersey.CustomersFixtures

  @create_attrs %{name: "some name", pindex: "123456"}
  @update_attrs %{name: "some updated name", pindex: "654321"}
  @invalid_attrs %{name: nil, pindex: nil}

  defp create_city(_) do
    city = city_fixture()
    %{city: city}
  end

  describe "Index" do
    setup [:create_city]

    test "lists all cities", %{conn: conn, city: city} do
      {:ok, _index_live, html} = live(conn, ~p"/cities")

      assert html =~ dgettext("city", "Listing Cities")
      assert html =~ city.pindex
    end

    test "saves new city", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cities")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", dgettext("city", "New City"))
               |> render_click()
               |> follow_redirect(conn, ~p"/cities/new")

      assert render(form_live) =~ dgettext("city", "New City")

      assert form_live
             |> form("#city-form", city: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, index_live, _html} =
               form_live
               |> form("#city-form", city: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/cities")

      html = render(index_live)
      assert html =~ dgettext("city", "City created successfully")

      assert html =~ @create_attrs.pindex
    end

    test "updates city in listing", %{conn: conn, city: city} do
      {:ok, index_live, _html} = live(conn, ~p"/cities")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#cities-#{city.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cities/#{city}/edit")

      assert render(form_live) =~ dgettext("city", "Edit City")

      assert form_live
             |> form("#city-form", city: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, index_live, _html} =
               form_live
               |> form("#city-form", city: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/cities")

      html = render(index_live)
      assert html =~ dgettext("city", "City updated successfully")
      assert html =~ @update_attrs.pindex
    end

    test "deletes city in listing", %{conn: conn, city: city} do
      {:ok, index_live, _html} = live(conn, ~p"/cities")

      assert index_live |> element("#cities-#{city.id} a", "Delete") |> render_click()

      refute has_element?(index_live, "#cities-#{city.id}")
    end
  end

  describe "Show" do
    setup [:create_city]

    test "displays city", %{conn: conn, city: city} do
      {:ok, _show_live, html} = live(conn, ~p"/cities/#{city}")

      assert html =~ dgettext("city", "Show City")
      assert html =~ city.pindex
    end

    test "updates city and returns to show", %{conn: conn, city: city} do
      {:ok, show_live, _html} = live(conn, ~p"/cities/#{city}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cities/#{city}/edit?return_to=show")

      assert render(form_live) =~ dgettext("city", "Edit City")

      assert form_live
             |> form("#city-form", city: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, show_live, _html} =
               form_live
               |> form("#city-form", city: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/cities/#{city}")

      html = render(show_live)
      assert html =~ dgettext("city", "City updated successfully")
      assert html =~ @update_attrs.pindex
    end
  end
end
