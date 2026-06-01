defmodule Jersey.CustomersTest do
  use Jersey.DataCase

  alias Jersey.Customers

  describe "customers" do
    alias Jersey.Customers.Customer

    import Jersey.CustomersFixtures

    @invalid_attrs %{name: nil, nick: nil}

    test "list_customers/0 returns all customers" do
      customer = customer_fixture()
      [loaded] = Customers.list_customers()

      assert loaded.id == customer.id
      assert loaded.name == customer.name
      assert loaded.nick == customer.nick
    end

    test "get_customer!/1 returns the customer with given id" do
      customer = customer_fixture()
      loaded = Customers.get_customer!(customer.id)

      assert loaded.id == customer.id
      assert loaded.name == customer.name
      assert loaded.nick == customer.nick
    end

    test "create_customer/1 with valid data creates a customer" do
      valid_attrs = %{name: "some name", nick: "some nick"}

      assert {:ok, %Customer{} = customer} = Customers.create_customer(valid_attrs)
      assert customer.name == "some name"
      assert customer.nick == "some nick"
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
  end

  describe "cities" do
    alias Jersey.Customers.City

    import Jersey.CustomersFixtures

    @invalid_attrs %{name: nil, pindex: nil}

    test "list_cities/0 returns all cities" do
      city = city_fixture()
      assert Customers.list_cities() == [city]
    end

    test "get_city!/1 returns the city with given id" do
      city = city_fixture()
      assert Customers.get_city!(city.id) == city
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
  end
end
