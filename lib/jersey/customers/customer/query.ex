defmodule Jersey.Customers.Customer.Query do
  import Ecto.Query

  alias Jersey.Customers.Customer

  def base, do: Customer

  def search(text, query \\ base()) do
    query
    |> where([c], ilike(c.nick, ^"%#{text}%") or ilike(c.name, ^"%#{text}%"))
    |> preload(:city)
  end

  def list(query \\ base()) do
    query |> order_by(desc: :id) |> preload(:city)
  end

  def get!(id, query \\ base()) do
    query |> where(id: ^id) |> preload(:city)
  end
end
