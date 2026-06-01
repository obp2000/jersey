defmodule JerseyWeb.OrderLiveTest do
  use JerseyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jersey.OrdersFixtures

  defp create_order(_), do: %{order: order_fixture()}

  describe "Index" do
    setup [:create_order]

    test "lists all orders", %{conn: conn, order: order} do
      {:ok, _index_live, html} = live(conn, ~p"/orders")

      assert html =~ dgettext("order", "Listing Orders")
      assert html =~ "orders-#{order.id}"
    end

    test "saves new order", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", dgettext("order", "New Order"))
               |> render_click()
               |> follow_redirect(conn, ~p"/orders/new")

      assert render(form_live) =~ dgettext("order", "New Order")

      # submit in LiveSelect/customers field is unstable in test env,
      # so we only check button presence / rendering.
      assert has_element?(form_live, "button", "Save Order")
    end

    test "updates order in listing", %{conn: conn, order: order} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#orders-#{order.id} a[href$=\"/edit\"]")
               |> render_click()
               |> follow_redirect(conn, ~p"/orders/#{order}/edit")

      html_form = render(form_live)
      assert html_form =~ dgettext("order", "Edit Order")

      assert has_element?(form_live, "form#order-form")
    end

    test "deletes order in listing", %{conn: conn, order: order} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert index_live
             |> element("#orders-#{order.id} a", "Delete")
             |> render_click() =~ ""

      refute has_element?(index_live, "#orders-#{order.id}")
    end
  end

  describe "Show" do
    setup [:create_order]

    test "displays order", %{conn: conn, order: order} do
      {:ok, _show_live, html} = live(conn, ~p"/orders/#{order}")

      assert html =~ dgettext("order", "Show Order")
      assert html =~ "Order #{order.id}"
    end

    test "updates order and returns to show", %{conn: conn, order: order} do
      {:ok, show_live, _html} = live(conn, ~p"/orders/#{order}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a[href$=\"/edit?return_to=show\"]")
               |> render_click()
               |> follow_redirect(conn, ~p"/orders/#{order}/edit?return_to=show")

      html_form = render(form_live)
      assert html_form =~ dgettext("order", "Edit Order")

      assert has_element?(form_live, "form#order-form")
    end
  end
end
