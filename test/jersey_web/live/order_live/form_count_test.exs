defmodule JerseyWeb.OrderLive.FormCountTest do
  use JerseyWeb.ConnCase
  import Phoenix.LiveViewTest
  import Jersey.{CustomersFixtures, ProductsFixtures, OrdersFixtures}

  describe "OrderLive.Form (Count button)" do
    test "shows Count when customer.city.pindex is set and order has order_items", %{conn: conn} do
      city = city_fixture(%{pindex: "190000"})
      customer = customer_fixture(%{city_id: city.id})
      product = product_fixture(%{density: 200, width: 150})
      order = order_fixture(%{customer_id: customer.id})

      order_item_fixture(%{
        order_id: order.id,
        product_id: product.id,
        amount: 3,
        price: 300
      })

      {:ok, form_view, _html} = live(conn, ~p"/orders/#{order.id}/edit")
      html = render(form_view)
      assert html =~ dgettext("order", "Count")

      assert form_view |> element("button", dgettext("order", "Count")) |> render_click() =~
               ~s(value="448")
    end
  end
end
