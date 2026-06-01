defmodule Jersey.Products.Product.Query do
  import Ecto.Query

  alias Jersey.Products.Product
  alias Jersey.Products

  def base do
    Product
  end

  def for_page(query \\ base(), page \\ 1, per_page \\ Products.default_per_page()) do
    offset = (page - 1) * per_page

    query
    |> order_by([p], desc: p.inserted_at)
    |> limit(^per_page)
    |> offset(^offset)
  end

  def order_by_inserted_at(query \\ base()) do
    query
    |> order_by(desc: :inserted_at)
  end

  def search(text, query \\ base()) do
    query
    |> where([c], ilike(c.name, ^"%#{text}%"))
  end
end
