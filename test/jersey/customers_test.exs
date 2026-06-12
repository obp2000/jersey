defmodule Jersey.CustomersTest do
  use Jersey.DataCase

  alias Jersey.Customers
  alias Jersey.Customers.{Customer, City}
  import Jersey.CustomersFixtures

  describe "customers" do
    @invalid_attrs %{name: nil, nick: nil}

    test "list_customers/0 returns all customers" do
      customer = customer_fixture()
      [loaded] = Customers.list_customers()

      assert loaded.id == customer.id
      assert loaded.name == customer.name
      assert loaded.nick == customer.nick
    end

    test "list_customers/0 returns customers ordered by inserted_at" do
      customer1 = customer_fixture(%{nick: "first", name: "First"})
      customer2 = customer_fixture(%{nick: "second", name: "Second"})

      _customer1 =
        Repo.update!(Ecto.Changeset.change(customer1, inserted_at: ~U[2024-01-01 10:00:00Z]))

      customer2 =
        Repo.update!(Ecto.Changeset.change(customer2, inserted_at: ~U[2024-01-02 10:00:00Z]))

      customers = Customers.list_customers()
      assert List.first(customers).id == customer2.id
    end

    test "list_customers/0 preloads city association" do
      city = city_fixture()
      customer_fixture(%{city_id: city.id})

      [customer] = Customers.list_customers()

      assert customer.city != nil
      assert customer.city.id == city.id
    end

    test "get_customer!/1 returns the customer with given id" do
      customer = customer_fixture()
      loaded = Customers.get_customer!(customer.id)

      assert loaded.id == customer.id
      assert loaded.name == customer.name
      assert loaded.nick == customer.nick
    end

    test "get_customer!/1 preloads city association" do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})

      loaded = Customers.get_customer!(customer.id)

      assert loaded.city != nil
      assert loaded.city.id == city.id
    end

    test "get_customer!/1 raises when customer not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Customers.get_customer!(99999)
      end
    end

    test "create_customer/1 with valid data creates a customer" do
      valid_attrs = %{name: "some name", nick: "some nick"}

      assert {:ok, %Customer{} = customer} = Customers.create_customer(valid_attrs)
      assert customer.name == "some name"
      assert customer.nick == "some nick"
    end

    test "create_customer/1 with city_id creates customer with city" do
      city = city_fixture()
      valid_attrs = %{name: "some name", nick: "some nick", city_id: city.id}

      assert {:ok, %Customer{} = customer} = Customers.create_customer(valid_attrs)
      assert customer.city_id == city.id
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Customers.create_customer(@invalid_attrs)
    end

    test "update_customer/2 with valid data updates the customer" do
      customer = customer_fixture()
      update_attrs = %{name: "some updated name", nick: "some updated nick"}

      assert {:ok, %Customer{} = customer} = Customers.update_customer(customer, update_attrs)
      assert customer.name == "some updated name"
      assert customer.nick == "some updated nick"
    end

    test "update_customer/2 updates city_id" do
      customer = customer_fixture()
      new_city = city_fixture(%{name: "New City", pindex: "999999"})

      assert {:ok, updated_customer} =
               Customers.update_customer(customer, %{city_id: new_city.id})

      assert updated_customer.city_id == new_city.id
    end

    test "update_customer/2 with invalid data returns error changeset" do
      customer = customer_fixture()
      assert {:error, %Ecto.Changeset{}} = Customers.update_customer(customer, @invalid_attrs)

      loaded = Customers.get_customer!(customer.id)
      assert loaded.id == customer.id
      assert loaded.name == customer.name
      assert loaded.nick == customer.nick
    end

    test "delete_customer/1 deletes the customer" do
      customer = customer_fixture()
      assert {:ok, %Customer{}} = Customers.delete_customer(customer)
      assert_raise Ecto.NoResultsError, fn -> Customers.get_customer!(customer.id) end
    end

    test "change_customer/1 returns a customer changeset" do
      customer = customer_fixture()
      assert %Ecto.Changeset{} = Customers.change_customer(customer)
    end

    test "change_customer/1 with attrs updates changeset" do
      customer = customer_fixture()
      changeset = Customers.change_customer(customer, %{nick: "updated nick"})

      assert get_change(changeset, :nick) == "updated nick"
    end
  end

  describe "search_customers/1" do
    test "searches by nick" do
      customer_fixture(%{nick: "john_doe", name: "John"})
      customer_fixture(%{nick: "jane_doe", name: "Jane"})
      customer_fixture(%{nick: "bob_smith", name: "Bob"})

      results = Customers.search_customers("john")

      assert length(results) == 1
      assert hd(results).nick == "john_doe"
    end

    test "searches by name" do
      customer_fixture(%{nick: "nick1", name: "Alexander"})
      customer_fixture(%{nick: "nick2", name: "Alexandra"})
      customer_fixture(%{nick: "nick3", name: "Bob"})

      results = Customers.search_customers("alex")

      assert length(results) == 2
    end

    test "case-insensitive search" do
      customer_fixture(%{nick: "TestUser", name: "Test Name"})

      results = Customers.search_customers("test")

      assert length(results) == 1
    end

    test "partial match search" do
      customer_fixture(%{nick: "superman", name: "Clark"})
      customer_fixture(%{nick: "spiderman", name: "Peter"})
      customer_fixture(%{nick: "batman", name: "Bruce"})

      results = Customers.search_customers("man")

      assert length(results) == 3
    end

    test "returns empty list when no match" do
      customer_fixture(%{nick: "john", name: "John"})

      results = Customers.search_customers("nonexistent")

      assert results == []
    end

    test "preloads city association in results" do
      city = city_fixture()
      customer_fixture(%{nick: "test", name: "Test", city_id: city.id})

      results = Customers.search_customers("test")

      assert hd(results).city != nil
    end

    test "handles special characters in search" do
      customer_fixture(%{nick: "user@domain", name: "User"})

      results = Customers.search_customers("@")

      assert length(results) == 1
    end
  end

  describe "full_customer_name/1" do
    test "returns full name with all fields" do
      city = city_fixture(%{pindex: "12345", name: "Yerevan"})

      customer =
        customer_fixture(%{nick: "nick", name: "John", address: "Street 1", city_id: city.id})

      # Need to reload customer with city preloaded
      customer = Jersey.Customers.get_customer!(customer.id) |> Repo.preload(:city)

      full_name = Customers.full_customer_name(customer)

      assert full_name =~ "nick"
      assert full_name =~ "John"
      assert full_name =~ "12345"
      assert full_name =~ "Yerevan"
      assert full_name =~ "Street 1"
    end

    test "excludes nil fields" do
      customer = %Jersey.Customers.Customer{nick: "nick", name: "John", address: nil, city: nil}

      assert Customers.full_customer_name(customer) == "nick John"
    end

    test "excludes empty string fields" do
      customer = %Jersey.Customers.Customer{nick: "", name: "John", address: "", city: nil}

      assert Customers.full_customer_name(customer) == "John"
    end

    test "handles customer without city" do
      customer = customer_fixture(%{nick: "nick", name: "John", address: "Street"})

      full_name = Customers.full_customer_name(customer)

      refute full_name =~ "Yerevan"
      assert full_name =~ "nick John Street"
    end
  end

  describe "cities" do
    alias Jersey.Customers.City

    @invalid_attrs %{name: nil, pindex: nil}

    test "list_cities/0 returns all cities" do
      city = city_fixture()
      assert Customers.list_cities() == [city]
    end

    test "list_cities/0 returns cities ordered by inserted_at" do
      city1 = city_fixture(%{name: "First City", pindex: "111111"})
      _city2 = city_fixture(%{name: "Second City", pindex: "222222"})

      cities = Customers.list_cities()

      # Should have both cities
      assert length(cities) >= 2
      # Check that ordering is deterministic (not random)
      assert hd(cities).id in [city1.id]
    end

    test "get_city!/1 returns the city with given id" do
      city = city_fixture()
      assert Customers.get_city!(city.id) == city
    end

    test "get_city!/1 raises when city not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Customers.get_city!(99999)
      end
    end

    test "create_city/1 with valid data creates a city" do
      valid_attrs = %{name: "some name", pindex: "12345"}

      assert {:ok, %City{} = city} = Customers.create_city(valid_attrs)
      assert city.name == "some name"
      assert city.pindex == "12345"
    end

    test "create_city/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Customers.create_city(@invalid_attrs)
    end

    test "update_city/2 with valid data updates the city" do
      city = city_fixture()
      update_attrs = %{name: "some updated name", pindex: "123456"}

      assert {:ok, %City{} = city} = Customers.update_city(city, update_attrs)
      assert city.name == "some updated name"
      assert city.pindex == "123456"
    end

    test "update_city/2 with invalid data returns error changeset" do
      city = city_fixture()
      assert {:error, %Ecto.Changeset{}} = Customers.update_city(city, @invalid_attrs)

      loaded = Customers.get_city!(city.id)
      assert loaded.id == city.id
      assert loaded.name == city.name
      assert loaded.pindex == city.pindex
    end

    test "delete_city/1 deletes the city" do
      city = city_fixture()
      assert {:ok, %City{}} = Customers.delete_city(city)
      assert_raise Ecto.NoResultsError, fn -> Customers.get_city!(city.id) end
    end

    test "change_city/1 returns a city changeset" do
      city = city_fixture()
      assert %Ecto.Changeset{} = Customers.change_city(city)
    end

    test "change_city/1 with attrs updates changeset" do
      city = city_fixture()
      changeset = Customers.change_city(city, %{pindex: "999999"})

      assert get_change(changeset, :pindex) == "999999"
    end
  end

  describe "search_cities/1" do
    test "searches by name" do
      city_fixture(%{name: "Yerevan", pindex: "0001"})
      city_fixture(%{name: "Gyumri", pindex: "0002"})
      city_fixture(%{name: "Vanadzor", pindex: "0003"})

      results = Customers.search_cities("yerevan")

      assert length(results) == 1
      assert hd(results).name == "Yerevan"
    end

    test "searches by pindex" do
      city_fixture(%{name: "City1", pindex: "123456"})
      city_fixture(%{name: "City2", pindex: "654321"})

      results = Customers.search_cities("123")

      assert length(results) == 1
      assert hd(results).pindex == "123456"
    end

    test "case-insensitive search" do
      city_fixture(%{name: "TestCity", pindex: "12345"})

      results = Customers.search_cities("test")

      assert length(results) == 1
    end

    test "partial match search" do
      city_fixture(%{name: "New York", pindex: "10001"})
      city_fixture(%{name: "Yorkshire", pindex: "20001"})

      results = Customers.search_cities("york")

      assert length(results) == 2
    end

    test "returns empty list when no match" do
      city_fixture(%{name: "Yerevan", pindex: "0001"})

      results = Customers.search_cities("nonexistent")

      assert results == []
    end

    test "handles special characters in search" do
      city_fixture(%{name: "St. Petersburg", pindex: "190000"})

      results = Customers.search_cities("st.")

      assert length(results) == 1
    end
  end

  describe "full_city_name/1" do
    test "returns pindex and name" do
      city = city_fixture(%{pindex: "12345", name: "Yerevan"})

      assert Customers.full_city_name(city) == "12345 Yerevan"
    end

    test "excludes nil pindex" do
      city = %Jersey.Customers.City{pindex: nil, name: "Yerevan"}

      assert Customers.full_city_name(city) == "Yerevan"
    end

    test "excludes nil name" do
      city = %Jersey.Customers.City{pindex: "12345", name: nil}

      assert Customers.full_city_name(city) == "12345"
    end

    test "returns empty string for nil city" do
      assert Customers.full_city_name(nil) == ""
    end
  end
end
