defmodule Jersey.Orders.Order.QueryTest do
  use Jersey.DataCase

  alias Jersey.Orders.{Order, Order.Query}
  alias Jersey.Customers.{Customer, City}
  import Jersey.OrdersFixtures
  import Jersey.CustomersFixtures

  describe "Jersey.Orders.Order.Query" do
    setup do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})
      order1 = order_fixture(%{customer_id: customer.id, address: "Address 1"})
      order2 = order_fixture(%{customer_id: customer.id, address: "Address 2"})
      order3 = order_fixture(%{customer_id: customer.id, address: "Address 3"})

      %{orders: [order1, order2, order3], customer: customer}
    end

    test "list/1 returns orders ordered by id desc" do
      query = Query.list()
      results = Repo.all(query)
      assert length(results) == 3
      ids = Enum.map(results, & &1.id)
      assert ids == Enum.sort(ids, :desc)
    end

    test "get!/2 returns order by id with customer and city preloaded", %{orders: [order | _rest]} do
      returned = Query.get!(order.id) |> Repo.one!()
      assert %Order{} = returned
      assert returned.id == order.id
      assert %Customer{} = returned.customer
      assert order.customer == returned.customer
      assert %City{} = returned.customer.city
      assert order.customer.city == returned.customer.city
    end
  end
end
