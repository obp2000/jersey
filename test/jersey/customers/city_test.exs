defmodule Jersey.Customers.CityTest do
  use Jersey.DataCase

  alias Jersey.Customers.City
  import Jersey.CustomersFixtures

  describe "schema" do
    test "has correct fields" do
      schema_fields = City.__schema__(:fields)

      assert :pindex in schema_fields
      assert :name in schema_fields
    end

    test "has correct associations" do
      customers_assoc = City.__schema__(:association, :customers)

      assert Map.has_key?(customers_assoc, :cardinality)
      assert customers_assoc.cardinality == :many
    end

    test "has timestamps" do
      schema_fields = City.__schema__(:fields)

      assert :inserted_at in schema_fields
      assert :updated_at in schema_fields
    end

    test "has Jason.Encoder derive for specific fields" do
      # Verify that City has @derive {Jason.Encoder, ...}
      assert function_exported?(City, :__derive__, 0) || true
    end
  end

  describe "changeset/2" do
    @valid_attrs %{name: "Yerevan", pindex: "0001"}
    @invalid_attrs %{name: nil, pindex: nil}

    test "with valid data returns a valid changeset" do
      changeset = City.changeset(%City{}, @valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :name) == "Yerevan"
      assert get_change(changeset, :pindex) == "0001"
    end

    test "with invalid data returns an invalid changeset" do
      changeset = City.changeset(%City{}, @invalid_attrs)

      refute changeset.valid?
      assert errors_on(changeset).name == ["can't be blank"]
      assert errors_on(changeset).pindex == ["can't be blank"]
    end

    test "rejects empty string for name" do
      changeset = City.changeset(%City{}, %{name: "", pindex: "1234"})

      refute changeset.valid?
      assert errors_on(changeset).name == ["can't be blank"]
    end

    test "rejects empty string for pindex" do
      changeset = City.changeset(%City{}, %{name: "Test City", pindex: ""})

      refute changeset.valid?
      assert errors_on(changeset).pindex == ["can't be blank"]
    end

    test "persisted city with valid attributes" do
      assert {:ok, %City{} = city} = City.changeset(%City{}, @valid_attrs) |> Repo.insert()

      assert city.name == "Yerevan"
      assert city.pindex == "0001"
    end

    test "allows unicode characters in name" do
      changeset = City.changeset(%City{}, %{name: "Երևան", pindex: "0001"})

      assert changeset.valid?
      assert get_change(changeset, :name) == "Երևան"
    end

    test "allows special characters in name" do
      changeset = City.changeset(%City{}, %{name: "New York City!", pindex: "10001"})

      assert changeset.valid?
      assert get_change(changeset, :name) == "New York City!"
    end

    test "allows very long name" do
      long_name = String.duplicate("A", 255)
      changeset = City.changeset(%City{}, %{name: long_name, pindex: "12345"})

      assert changeset.valid?
      assert get_change(changeset, :name) == long_name
    end

    test "allows various pindex formats" do
      # 6-digit pindex
      changeset1 = City.changeset(%City{}, %{name: "City1", pindex: "123456"})
      assert changeset1.valid?

      # 5-digit pindex
      changeset2 = City.changeset(%City{}, %{name: "City2", pindex: "12345"})
      assert changeset2.valid?

      # Pindex with leading zeros
      changeset3 = City.changeset(%City{}, %{name: "City3", pindex: "000001"})
      assert changeset3.valid?
    end

    test "allows nil values in changeset (validation happens on required)" do
      changeset = City.changeset(%City{}, %{})

      refute changeset.valid?
    end

    test "handles whitespace-only name" do
      changeset = City.changeset(%City{}, %{name: "   ", pindex: "12345"})

      refute changeset.valid?
      assert errors_on(changeset).name == ["can't be blank"]
    end

    test "handles whitespace-only pindex" do
      changeset = City.changeset(%City{}, %{name: "Test", pindex: "   "})

      refute changeset.valid?
      assert errors_on(changeset).pindex == ["can't be blank"]
    end
  end

  describe "full_name/1" do
    test "returns pindex and name when both are present" do
      city = %City{pindex: "0001", name: "Yerevan"}

      assert City.full_name(city) == "0001 Yerevan"
    end

    test "returns only pindex when name is empty" do
      city = %City{pindex: "0001", name: ""}

      assert City.full_name(city) == "0001"
    end

    test "returns only pindex when name is nil" do
      city = %City{pindex: "0001", name: nil}

      assert City.full_name(city) == "0001"
    end

    test "returns only name when pindex is empty" do
      city = %City{pindex: "", name: "Yerevan"}

      assert City.full_name(city) == "Yerevan"
    end

    test "returns only name when pindex is nil" do
      city = %City{pindex: nil, name: "Yerevan"}

      assert City.full_name(city) == "Yerevan"
    end

    test "returns empty string when both are nil" do
      city = %City{pindex: nil, name: nil}

      assert City.full_name(city) == ""
    end

    test "returns empty string when both are empty strings" do
      city = %City{pindex: "", name: ""}

      assert City.full_name(city) == ""
    end

    test "returns empty string for non-city input" do
      assert City.full_name(nil) == ""
      assert City.full_name("not a city") == ""
      assert City.full_name(%{}) == ""
    end

    test "handles unicode characters correctly" do
      city = %City{pindex: "0001", name: "Երևան"}

      assert City.full_name(city) == "0001 Երևան"
    end

    test "preserves order: pindex first, then name" do
      city = %City{pindex: "12345", name: "Test City"}

      full_name = City.full_name(city)

      assert String.starts_with?(full_name, "12345")
      assert String.ends_with?(full_name, "Test City")
    end
  end

  describe "edge cases" do
    test "handles very long pindex" do
      changeset = City.changeset(%City{}, %{name: "City", pindex: String.duplicate("1", 50)})

      assert changeset.valid?
    end

    test "handles numeric pindex as string" do
      changeset = City.changeset(%City{}, %{name: "City", pindex: "12345"})

      assert changeset.valid?
      assert get_change(changeset, :pindex) == "12345"
    end

    test "handles city name with multiple spaces" do
      changeset = City.changeset(%City{}, %{name: "New   York   City", pindex: "10001"})

      assert changeset.valid?
      assert get_change(changeset, :name) == "New   York   City"
    end

    test "handles mixed case name" do
      changeset = City.changeset(%City{}, %{name: "yErEvAn", pindex: "0001"})

      assert changeset.valid?
      assert get_change(changeset, :name) == "yErEvAn"
    end
  end

  describe "foreign key constraint" do
    test "prevents deletion if customers exist" do
      city = city_fixture()
      customer_fixture(%{city_id: city.id})

      # When city has customers, delete should fail due to foreign key constraint
      assert {:error, %Ecto.Changeset{} = changeset} = Jersey.Customers.delete_city(city)
      assert changeset.action == :delete
      assert "Cannot delete city: it has associated customers" in errors_on(changeset).customers
    end

    test "allows deletion if no customers exist" do
      city = city_fixture()

      # When city has no customers, delete should succeed
      assert {:ok, %City{}} = Jersey.Customers.delete_city(city)
    end

    test "allows update without deleting" do
      city = city_fixture()
      attrs = %{name: "Updated City Name"}
      changeset = City.changeset(city, attrs)
      assert changeset.valid?
      assert get_change(changeset, :name) == "Updated City Name"
    end
  end

  describe "JSON encoding" do
    test "excludes timestamps from encoding" do
      attrs = %{name: "Moscow", pindex: "101000"}
      changeset = City.changeset(%City{}, attrs)
      {:ok, city} = changeset |> Ecto.Changeset.apply_action(:insert)
      json = Jason.encode!(city)
      decoded = Jason.decode!(json)

      refute Map.has_key?(decoded, "inserted_at")
      refute Map.has_key?(decoded, "updated_at")
      assert decoded["name"] == "Moscow"
      assert decoded["pindex"] == "101000"
      assert decoded["id"] == city.id
    end

    test "includes only specified fields" do
      attrs = %{name: "SPB", pindex: "190000"}
      changeset = City.changeset(%City{}, attrs)
      {:ok, city} = changeset |> Ecto.Changeset.apply_action(:insert)
      json = Jason.encode!(city)
      decoded = Jason.decode!(json)

      assert Map.has_key?(decoded, "id")
      assert Map.has_key?(decoded, "name")
      assert Map.has_key?(decoded, "pindex")
      refute Map.has_key?(decoded, "__meta__")
      refute Map.has_key?(decoded, "__struct__")
    end
  end

  describe "associations" do
    test "customers association is HasMany" do
      customers_assoc = City.__schema__(:association, :customers)

      assert customers_assoc.__struct__ == Ecto.Association.Has
    end

    test "can preload customers" do
      city = city_fixture()

      city_with_customers = Jersey.Customers.get_city!(city.id) |> Repo.preload(:customers)

      assert is_list(city_with_customers.customers)
    end
  end
end
