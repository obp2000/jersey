defmodule Jersey.Orders.Order.Query do
  import Ecto.Query
  alias Jersey.Orders.Order

  def base, do: Order

  def list(query \\ base()) do
    query |> order_by(desc: :inserted_at) |> preload(customer: :city, order_items: :product)
  end

  def get!(id, query \\ base()) do
    query |> where(id: ^id) |> preload(customer: :city, order_items: :product)
  end
end
