defmodule Jersey.Orders.Order.Query do
  import Ecto.Query
  alias Jersey.Orders.Order
  alias Order.Calculation

  def base, do: Order

  def list(query \\ base()) do
    min_order_items_price_for_post_discount =
      Calculation.min_order_items_price_for_post_discount()

    with_discount_rate = Decimal.sub(1, Calculation.discount_rate()) |> Decimal.to_float()

    query
    |> join(:left, [order], assoc(order, :order_items))
    |> group_by([order, _order_item], order.id)
    |> select_merge([order, order_item], %{
      order_items_price: sum(order_item.amount * order_item.price),
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
    |> order_by([order], desc: order.id)
    |> preload([order], customer: :city, order_items: :product)
  end

  def get!(id, query \\ base()) do
    list(query) |> where([order], order.id == ^id)
  end
end
