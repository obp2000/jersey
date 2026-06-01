defmodule Jersey.Customers.City.QueryTest do
  use Jersey.DataCase
  alias Jersey.Customers.{City, City.Query}
  import Jersey.CustomersFixtures

  describe "Jersey.Customers.City.Query.search/2" do
    setup do
      city_fixture(%{name: "Yerevan", pindex: "0001"})
      city_fixture(%{name: "Gyumri", pindex: "0201"})
      city_fixture(%{name: "New Yerevan", pindex: "0303"})
      :ok
    end

    test "searches by name (partial, case-insensitive)" do
      assert Query.search("yere", City) |> Repo.all() |> Enum.map(& &1.name) |> Enum.sort() == [
               "New Yerevan",
               "Yerevan"
             ]
    end

    test "searches by pindex (partial, case-insensitive)" do
      query = Query.search("001", City)
      results = Repo.all(query)

      assert Enum.map(results, & &1.pindex) |> Enum.sort() == ["0001"]
    end

    test "returns empty list when there are no matches" do
      query = Query.search("zzz", City)
      assert Repo.all(query) == []
    end

    test "empty text returns all cities" do
      query = Query.search("", City)
      results = Repo.all(query)

      assert length(results) == 3
    end
  end
end
