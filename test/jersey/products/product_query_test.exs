defmodule Jersey.Products.Product.QueryTest do
  use Jersey.DataCase, async: true

  alias Jersey.Products.{Product, Product.Query}
  import Jersey.ProductsFixtures

  describe "Jersey.Products.Product.Query" do
    test "for_page/3 uses base query + default args and applies limit/offset" do
      _p1 = product_fixture(%{name: "p1"})
      _p2 = product_fixture(%{name: "p2"})
      p3 = product_fixture(%{name: "p3"})

      per_page = 1
      q = Query.for_page(Product, 1, per_page)
      entries = Repo.all(q)
      assert length(entries) == 1
      assert hd(entries).id == p3.id

      q2 = Query.for_page(Product, 2, per_page)
      entries2 = Repo.all(q2)
      assert length(entries2) == 1

      # newest first with limit/offset => page2 returns the second newest
      second_newest_id =
        Product
        |> Query.order_by_inserted_at()
        |> Repo.all()
        |> Enum.drop(1)
        |> hd()
        |> Map.get(:id)

      assert hd(entries2).id == second_newest_id

      q_default = Query.for_page()
      entries_default = Repo.all(q_default)
      assert length(entries_default) >= 1
      assert hd(entries_default).id == p3.id
    end

    test "order_by_inserted_at/1 uses descending id" do
      old = product_fixture(%{name: "old"})
      new = product_fixture(%{name: "new"})

      q = Query.order_by_inserted_at(Product)
      [first, second] = Repo.all(q) |> Enum.take(2)

      assert first.id == new.id
      assert second.id == old.id
    end

    test "search/2 returns ilike match on name" do
      product_fixture(%{name: "Alpha"})
      product_fixture(%{name: "Beta"})
      gamma = product_fixture(%{name: "Gamma"})
      q = Query.search("am", Product)
      results = Repo.all(q)

      assert Enum.any?(results, &(&1.id == gamma.id))
    end

    test "search/2 with empty string returns all (ilike '%%')" do
      p1 = product_fixture(%{name: "A"})
      p2 = product_fixture(%{name: "B"})

      results = Query.search("", Product) |> Repo.all()
      assert Enum.any?(results, &(&1.id == p1.id))
      assert Enum.any?(results, &(&1.id == p2.id))
    end
  end
end
