defmodule Jersey.OrdersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jersey.Orders` context.
  """

  alias Jersey.CustomersFixtures
  alias Jersey.Orders
  alias Jersey.ProductsFixtures

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    customer = CustomersFixtures.customer_fixture()

    attrs_with_customer =
      if Map.has_key?(attrs, :customer_id) do
        attrs
      else
        Map.put(attrs, :customer_id, customer.id)
      end

    {:ok, order} = Orders.create_order(attrs_with_customer)

    # Preload associations for changeset operations
    Orders.get_order!(order.id)
  end

  def order_item_fixture(attrs \\ %{}) do
    order = order_fixture()
    product = ProductsFixtures.product_fixture()

    attrs_with_order_and_product =
      attrs
      |> Map.put_new(:order_id, order.id)
      |> Map.put_new(:product_id, product.id)
      |> Map.put(:order, order)

    item_attrs =
      %{amount: "120.5", price: "120.5"}
      |> Map.merge(attrs_with_order_and_product)

    {:ok, order_item} =
      Jersey.Orders.create_order_item(item_attrs)

    # Ensure associations are loaded because OrderItem.changeset/2
    # computes totals using the product struct (density/width).
    Jersey.Repo.preload(order_item, :product)
  end
end
