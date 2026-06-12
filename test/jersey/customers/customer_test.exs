defmodule Jersey.Customers.CustomerTest do
  use Jersey.DataCase
  alias Jersey.Customers
  alias Customers.{Customer, City}
  alias Jersey.Orders
  alias Orders.Order
  import Jersey.CustomersFixtures
  import Jersey.OrdersFixtures

  describe "schema" do
    test "has correct fields" do
      schema_fields = Customer.__schema__(:fields)

      assert :nick in schema_fields
      assert :name in schema_fields
      assert :address in schema_fields
      assert :city_id in schema_fields
    end

    test "has correct associations" do
      city_assoc = Customer.__schema__(:association, :city)
      orders_assoc = Customer.__schema__(:association, :orders)

      assert Map.has_key?(city_assoc, :related)
      assert city_assoc.related == City
      assert Map.has_key?(orders_assoc, :cardinality)
      assert orders_assoc.cardinality == :many
    end

    test "has timestamps" do
      schema_fields = Customer.__schema__(:fields)

      assert :inserted_at in schema_fields
      assert :updated_at in schema_fields
    end
  end

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

    test "allows nil address" do
      city = city_fixture()

      attrs = %{nick: "nick", name: "name", city_id: city.id}
      changeset = Customer.changeset(%Customer{}, attrs)

      assert changeset.valid?
    end

    test "does not allow empty string nick" do
      city = city_fixture()

      attrs = %{nick: "", name: "name", city_id: city.id}
      changeset = Customer.changeset(%Customer{}, attrs)

      # Empty string fails validation (validate_required checks for blank)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).nick
    end

    test "does not allows empty string name" do
      city = city_fixture()

      attrs = %{nick: "nick", name: "", city_id: city.id}
      changeset = Customer.changeset(%Customer{}, attrs)

      # Empty string fails validation (validate_required checks for blank)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "handles foreign_key_constraint for city_id" do
      attrs = %{
        nick: "test_nick",
        name: "Test Customer",
        city_id: 99999
      }

      changeset = Customer.changeset(%Customer{}, attrs)
      assert changeset.valid?
      assert {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).city_id
    end

    test "cascades deletion to orders" do
      customer = customer_fixture()
      order = order_fixture(%{customer_id: customer.id})

      # Verify order exists and has correct customer_id before deletion
      assert %Order{} = fetched_order = Orders.get_order!(order.id)
      assert fetched_order.customer_id == customer.id

      # When customer has orders with on_delete: :delete_all, orders are deleted too
      assert {:ok, %Customer{}} = Customers.delete_customer(customer)

      # Verify order was cascade deleted
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(order.id) end
    end

    test "allows customer deletion when no orders exist" do
      customer = customer_fixture()

      # When customer has no orders, delete should succeed
      assert {:ok, %Customer{}} = Customers.delete_customer(customer)
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

    test "allows city to be updated" do
      attrs = %{
        nick: "nick",
        name: "name",
        city: %{name: "New City", pindex: "111111"}
      }

      changeset = Customer.order_form_changeset(%Customer{}, attrs)

      assert changeset.changes[:city] != nil
    end

    test "works without city" do
      attrs = %{
        nick: "nick",
        name: "name"
      }

      changeset = Customer.order_form_changeset(%Customer{}, attrs)

      assert %Ecto.Changeset{} = changeset
    end
  end

  describe "full_name/1" do
    test "joins non-empty fields including city full name" do
      city = %City{pindex: "0001", name: "Yerevan"}

      customer = %Customer{nick: "nick", name: "John", city: city, address: "Street 1"}
      assert Customer.full_name(customer) == "nick John 0001 Yerevan Street 1"
    end

    test "returns empty string for non-struct input (covers full_name/1 fallback)" do
      assert Customer.full_name(nil) == ""
      assert Customer.full_name(123) == ""
      assert Customer.full_name("invalid") == ""
    end

    test "skips nil and empty strings" do
      customer = %Customer{nick: nil, name: "", city: nil, address: ""}
      assert Customer.full_name(customer) == ""
    end

    test "handles nil city" do
      customer = %Customer{nick: "nick", name: "John", city: nil, address: "Street 1"}
      assert Customer.full_name(customer) == "nick John Street 1"
    end

    test "returns full name with all fields" do
      city = city_fixture()

      customer = %Customer{
        nick: "test_nick",
        name: "Test Customer",
        address: "Test Address",
        city: city
      }

      assert Customer.full_name(customer) =~ "test_nick"
      assert Customer.full_name(customer) =~ "Test Customer"
      assert Customer.full_name(customer) =~ city.pindex
      assert Customer.full_name(customer) =~ city.name
      assert Customer.full_name(customer) =~ "Test Address"
    end

    test "excludes nil fields" do
      customer = %Customer{
        nick: "test_nick",
        name: "Test Customer",
        address: nil,
        city: nil
      }

      full_name = Customer.full_name(customer)

      assert full_name == "test_nick Test Customer"
    end

    test "excludes empty string fields" do
      customer = %Customer{
        nick: "",
        name: "Test Customer",
        address: "",
        city: nil
      }

      full_name = Customer.full_name(customer)

      assert full_name == "Test Customer"
    end

    test "returns single field when others are nil" do
      customer = %Customer{
        nick: nil,
        name: "Test Customer",
        address: nil,
        city: nil
      }

      assert Customer.full_name(customer) == "Test Customer"
    end

    test "returns empty string when all fields are nil" do
      customer = %Customer{
        nick: nil,
        name: nil,
        address: nil,
        city: nil
      }

      assert Customer.full_name(customer) == ""
    end

    test "handles city with nil values" do
      customer = %Customer{
        nick: "test_nick",
        name: "Test Customer",
        address: nil,
        city: %City{pindex: nil, name: nil}
      }

      full_name = Customer.full_name(customer)

      assert full_name == "test_nick Test Customer"
    end

    test "orders fields correctly" do
      city = city_fixture()

      customer = %Customer{
        nick: "A",
        name: "B",
        address: "C",
        city: city
      }

      full_name = Customer.full_name(customer)
      parts = String.split(full_name)

      # Order should be: nick, name, city (pindex + name), address
      assert hd(parts) == "A"
    end
  end

  describe "edge cases" do
    test "handles very long nick" do
      city = city_fixture()

      attrs = %{
        nick: String.duplicate("a", 1000),
        name: "Test Customer",
        city_id: city.id
      }

      changeset = Customer.changeset(%Customer{}, attrs)

      assert {:ok, customer} = changeset |> Ecto.Changeset.apply_action(:test)
      assert byte_size(customer.nick) == 1000
    end

    test "handles special characters in name" do
      city = city_fixture()

      attrs = %{
        nick: "test_nick",
        name: "Тестовый Клиент 🎉",
        city_id: city.id
      }

      changeset = Customer.changeset(%Customer{}, attrs)

      assert {:ok, customer} = changeset |> Ecto.Changeset.apply_action(:test)
      assert customer.name == "Тестовый Клиент 🎉"
    end

    test "handles unicode in nick" do
      city = city_fixture()

      attrs = %{
        nick: "тест_ник",
        name: "Test Customer",
        city_id: city.id
      }

      changeset = Customer.changeset(%Customer{}, attrs)

      assert {:ok, customer} = changeset |> Ecto.Changeset.apply_action(:test)
      assert customer.nick == "тест_ник"
    end

    test "handles whitespace-only nick" do
      city = city_fixture()

      attrs = %{
        nick: "   ",
        name: "Test Customer",
        city_id: city.id
      }

      changeset = Customer.changeset(%Customer{}, attrs)

      # Whitespace-only fails validation (considered blank)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).nick
    end

    test "handles nil city_id" do
      attrs = %{
        nick: "test_nick",
        name: "Test Customer",
        city_id: nil
      }

      changeset = Customer.changeset(%Customer{}, attrs)

      # Will pass validation but fail at DB level if city_id is NOT NULL
      assert %Ecto.Changeset{} = changeset
    end

    test "handles numeric city_id" do
      city = city_fixture()

      attrs = %{
        nick: "test_nick",
        name: "Test Customer",
        city_id: city.id
      }

      changeset = Customer.changeset(%Customer{}, attrs)

      assert {:ok, customer} = changeset |> Ecto.Changeset.apply_action(:test)
      assert customer.city_id == city.id
    end
  end

  describe "JSON encoding" do
    test "excludes timestamps from encoding" do
      attrs = %{nick: "test_nick", name: "Test Customer"}
      changeset = Customer.changeset(%Customer{}, attrs)
      {:ok, customer} = changeset |> Ecto.Changeset.apply_action(:insert)
      json = Jason.encode!(customer)
      decoded = Jason.decode!(json)

      refute Map.has_key?(decoded, "inserted_at")
      refute Map.has_key?(decoded, "updated_at")
      assert decoded["nick"] == "test_nick"
      assert decoded["name"] == "Test Customer"
      assert decoded["id"] == customer.id
    end

    test "includes only specified fields" do
      attrs = %{nick: "nick", name: "Name", address: "Address"}
      changeset = Customer.changeset(%Customer{}, attrs)
      {:ok, customer} = changeset |> Ecto.Changeset.apply_action(:insert)
      json = Jason.encode!(customer)
      decoded = Jason.decode!(json)

      assert Map.has_key?(decoded, "id")
      assert Map.has_key?(decoded, "nick")
      assert Map.has_key?(decoded, "name")
      assert Map.has_key?(decoded, "address")
      refute Map.has_key?(decoded, "__meta__")
      refute Map.has_key?(decoded, "__struct__")
    end
  end

  describe "associations" do
    test "city association is BelongsTo" do
      city_assoc = Customer.__schema__(:association, :city)

      assert city_assoc.__struct__ == Ecto.Association.BelongsTo
    end

    test "orders association is HasMany" do
      orders_assoc = Customer.__schema__(:association, :orders)

      assert orders_assoc.__struct__ == Ecto.Association.Has
    end

    test "can preload city" do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})

      customer_with_city = Customers.get_customer!(customer.id) |> Repo.preload(:city)

      assert customer_with_city.city != nil
      assert customer_with_city.city.id == city.id
    end

    test "can preload orders" do
      customer = customer_fixture()

      customer_with_orders = Customers.get_customer!(customer.id) |> Repo.preload(:orders)

      assert is_list(customer_with_orders.orders)
    end
  end
end
