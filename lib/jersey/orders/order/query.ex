defmodule Jersey.Orders.Order.Query do
  import Ecto.Query
  alias Jersey.Orders.Order
  alias Order.Calculation

  def base, do: Order

  def list(query \\ base()) do
    query
    |> join(:left, [order], assoc(order, :order_items))
    |> group_by([order, _order_item], order.id)
    |> select_merge([_order, order_item], %{
      order_items_price: sum(order_item.amount * order_item.price)
    })
    |> select_total_price()
    |> order_by([order], desc: order.id)
    |> preload([order], customer: :city, order_items: :product)
  end

  defp select_total_price(query) do
    min_order_items_price_for_post_discount =
      Calculation.min_order_items_price_for_post_discount()

    with_discount_rate = 1 |> Decimal.sub(Calculation.discount_rate()) |> Decimal.to_float()

    query
    |> select_merge([_order, order_item], %{
      total_price:
        fragment(
          """
            ROUND(SUM(amount * price) + (COALESCE(post_cost, 0) + COALESCE(packet, 0)) *
              CASE WHEN SUM(amount * price) >= ? THEN ? ELSE 1.0
            END)
          """,
          ^min_order_items_price_for_post_discount,
          ^with_discount_rate
        )
    })
  end

  def get!(id, query \\ base()) do
    list(query) |> where([order], order.id == ^id)
  end
end
