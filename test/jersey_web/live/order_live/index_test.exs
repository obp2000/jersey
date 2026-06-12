defmodule JerseyWeb.OrderLive.IndexTest do
  use JerseyWeb.ConnCase
  import Phoenix.LiveViewTest
  import Jersey.{CustomersFixtures, OrdersFixtures}

  describe "OrderLive.Index" do
    setup %{conn: conn} do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})
      order = order_fixture(%{customer_id: customer.id})
      %{conn: conn, customer: customer, order: order}
    end

    test "lists all orders", %{conn: conn, customer: customer, order: order} do
      {:ok, _index_live, html} = live(conn, ~p"/orders")

      assert html =~ dgettext("order", "Listing Orders")
      assert html =~ Integer.to_string(order.id)
      assert html =~ customer.nick
    end

    test "deletes order in listing", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/orders")

      assert index_live |> element("#orders a", "Delete") |> render_click()
      refute has_element?(index_live, "#orders a", "Delete")
    end
  end
end
