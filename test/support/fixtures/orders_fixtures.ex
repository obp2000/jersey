defmodule Jersey.OrdersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jersey.Orders` context.
  """

  alias Jersey.CustomersFixtures
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

    {:ok, order} = Jersey.Orders.create_order(attrs_with_customer)

    # Preload associations for changeset operations
    Jersey.Orders.get_order!(order.id)
  end

  @doc """
  Generate a order_item.
  """
  def order_item_fixture(attrs \\ %{}) do
    order = order_fixture()
    product = ProductsFixtures.product_fixture()

    item_attrs =
      %{order_id: order.id, product_id: product.id, amount: "120.5", price: "120.5"}
      |> Map.merge(attrs)

    # OrderItem.changeset/2 deletes the `:product` association but does not
    # currently delete the `:order`/`:order_id`. However, depending on
    # association casting timing, `order_id` could be nil, so we ensure it
    # after insert.
    # `order_item.changeset/2` currently syncs product_id but relies on
    # casting :order_id to persist association. Ensure the inserted row
    # has `order_id` set by passing it both as field and association.
    {:ok, order_item} =
      Jersey.Orders.create_order_item(item_attrs |> Map.put(:order, order))

    # Ensure associations are loaded because OrderItem.changeset/2
    # computes totals using the product struct (density/width).
    Jersey.Repo.preload(order_item, :product)
  end
end
