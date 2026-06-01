defmodule Jersey.Customers.CustomerTest do
  use Jersey.DataCase
  alias Jersey.Customers.{Customer, City}
  import Jersey.CustomersFixtures

  describe "changeset/2" do
    test "with valid data returns a valid changeset" do
      city = city_fixture()

      attrs = %{nick: "nick", name: "name", address: "Some street", city_id: city.id}
      changeset = Customer.changeset(%Customer{}, attrs)

      assert changeset.valid?
    end

    test "with nil nick returns an invalid changeset" do
      city = city_fixture()

      attrs = %{nick: nil, name: "name", address: "Some street", city_id: city.id}
      changeset = Customer.changeset(%Customer{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).nick
    end

    test "with nil name returns an invalid changeset" do
      city = city_fixture()

      attrs = %{nick: "nick", name: nil, address: "Some street", city_id: city.id}
      changeset = Customer.changeset(%Customer{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end
  end

  describe "order_form_changeset/2" do
    test "validates and prepares city association casting" do
      city = city_fixture()

      attrs = %{
        nick: "nick",
        name: "name",
        address: "Some street",
        city: %{id: city.id, pindex: city.pindex, name: city.name}
      }

      changeset = Customer.order_form_changeset(%Customer{}, attrs)
      assert changeset.valid?
      city = get_assoc(changeset, :city, :struct)
      assert city.pindex == city.pindex
      assert city.name == city.name
    end
  end

  describe "full_name/1" do
    test "joins non-empty fields including city full name" do
      city = %City{pindex: "0001", name: "Yerevan"}

      customer = %Customer{nick: "nick", name: "John", city: city, address: "Street 1"}
      assert Customer.full_name(customer) == "nick John 0001 Yerevan Street 1"
    end

    test "skips nil and empty strings" do
      customer = %Customer{nick: nil, name: "", city: nil, address: ""}
      assert Customer.full_name(customer) == ""
    end

    test "handles nil city" do
      customer = %Customer{nick: "nick", name: "John", city: nil, address: "Street 1"}
      assert Customer.full_name(customer) == "nick John Street 1"
    end
  end
end
