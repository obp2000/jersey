defmodule Jersey.Customers.Customer.QueryTest do
  use Jersey.DataCase

  alias Jersey.Customers.{City, Customer, Customer.Query}

  import Jersey.CustomersFixtures

  describe "Jersey.Customers.Customer.Query" do
    setup do
      city1 = city_fixture(%{name: "Yerevan City", pindex: "0001"})
      city2 = city_fixture(%{name: "Gyumri City", pindex: "0201"})

      %Customer{}
      |> Customer.changeset(%{
        nick: "john_doe",
        name: "John",
        address: "Street 1",
        city_id: city1.id
      })
      |> Repo.insert!()

      %Customer{}
      |> Customer.changeset(%{
        nick: "maria",
        name: "Maria",
        address: "Street 2",
        city_id: city2.id
      })
      |> Repo.insert!()

      %Customer{}
      |> Customer.changeset(%{
        nick: "evan",
        name: "New John",
        address: "Street 3",
        city_id: city1.id
      })
      |> Repo.insert!()

      :ok
    end

    test "search/2 filters by nick or name (partial, case-insensitive) and preloads city" do
      query = Query.search("john", Customer)
      results = Repo.all(query)

      assert Enum.map(results, & &1.name) |> Enum.sort() == ["John", "New John"]

      # preload(:city)
      assert Enum.all?(results, &has_city?/1)
    end

    test "search/2 returns empty list when there are no matches" do
      query = Query.search("zzz", Customer)
      assert Repo.all(query) == []
    end

    test "search/2 with empty text returns all customers" do
      query = Query.search("", Customer)
      results = Repo.all(query)

      assert length(results) == 3
      assert Enum.all?(results, &has_city?/1)
    end

    test "list/1 preloads city" do
      query = Query.list(Customer)
      results = Repo.all(query)

      assert Enum.all?(results, &has_city?/1)
      assert length(results) == 3
    end

    test "get!/2 returns customer by id with city preloaded" do
      %Customer{} = customer = Repo.one(from c in Customer, where: c.nick == "john_doe")

      returned = Query.get!(customer.id) |> Repo.one()

      assert %Customer{} = returned
      assert returned.id == customer.id
      assert %City{} = returned.city
    end
  end

  def has_city?(%{city: %City{}}), do: true

  def has_city?(_), do: false
end
