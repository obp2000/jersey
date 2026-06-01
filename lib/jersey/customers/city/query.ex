defmodule Jersey.Customers.City.Query do
  import Ecto.Query

  alias Jersey.Customers.City

  def base do
    City
  end

  def search(text, query \\ base()) do
    query
    |> where([c], ilike(c.name, ^"%#{text}%") or ilike(c.pindex, ^"%#{text}%"))
  end
end
