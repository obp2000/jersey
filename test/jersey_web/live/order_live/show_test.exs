defmodule JerseyWeb.OrderLive.ShowTest do
  use JerseyWeb.ConnCase
  import Phoenix.LiveViewTest
  import Jersey.{CustomersFixtures, OrdersFixtures}
  alias Jersey.Customers

  describe "OrderLive.Show" do
    test "renders order id", %{conn: conn} do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id, nick: "nick-1"})
      order = order_fixture(%{customer_id: customer.id})

      {:ok, _show_live, html} = live(conn, ~p"/orders/#{order}")

      assert html =~ "Order #{order.id}"
    end

    test "renders customer full name", %{conn: conn} do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id, nick: "nick-2", name: "name-2"})
      order = order_fixture(%{customer_id: customer.id})

      {:ok, _show_live, html} = live(conn, ~p"/orders/#{order}")

      assert html =~ Customers.full_customer_name(customer)
    end

    test "has navigation links", %{conn: conn} do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})
      order = order_fixture(%{customer_id: customer.id})

      {:ok, _show_live, html} = live(conn, ~p"/orders/#{order}")

      assert html =~ "hero-arrow-left"
      assert html =~ ~p"/orders/#{order}/edit?return_to=show"
    end
  end
end
