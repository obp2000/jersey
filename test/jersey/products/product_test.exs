defmodule Jersey.Products.ProductTest do
  use Jersey.DataCase

  alias Jersey.Products
  alias Products.Product
  alias Jersey.{ProductsFixtures, OrdersFixtures}

  defp is_decimal(val), do: is_struct(val, Decimal)

  describe "schema" do
    test "has correct fields" do
      schema_fields = Product.__schema__(:fields)

      assert :name in schema_fields
      assert :price in schema_fields
      assert :weight in schema_fields
      assert :width in schema_fields
      assert :density in schema_fields
      assert :dollar_price in schema_fields
      assert :dollar_rate in schema_fields
      assert :width_shop in schema_fields
      assert :density_shop in schema_fields
      assert :weight_for_count in schema_fields
      assert :length_for_count in schema_fields
      assert :price_pre in schema_fields
      assert :image in schema_fields
    end

    test "has correct virtual fields" do
      virtual_fields = Product.__schema__(:virtual_fields)

      assert :density_for_count in virtual_fields
      assert :meters_in_roll in virtual_fields
      assert :prices in virtual_fields
    end

    test "has correct associations" do
      order_items_assoc = Product.__schema__(:association, :order_items)

      assert Map.has_key?(order_items_assoc, :cardinality)
      assert order_items_assoc.cardinality == :many
    end

    test "has timestamps" do
      schema_fields = Product.__schema__(:fields)

      assert :inserted_at in schema_fields
      assert :updated_at in schema_fields
    end
  end

  describe "changeset/2" do
    test "validates required fields: name" do
      attrs = %{price: 42}

      changeset = Product.changeset(%Product{}, attrs)

      assert {:error, changeset} = changeset |> Ecto.Changeset.apply_action(:test)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates required fields: price" do
      attrs = %{name: "Test Product"}

      changeset = Product.changeset(%Product{}, attrs)

      assert {:error, changeset} = changeset |> Ecto.Changeset.apply_action(:test)
      assert %{price: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid attributes" do
      attrs = %{
        name: "Test Product",
        price: 100,
        weight: Decimal.new("100.5"),
        width: 150,
        density: 200
      }

      changeset = Product.changeset(%Product{}, attrs)

      assert {:ok, product} = changeset |> Ecto.Changeset.apply_action(:test)
      assert product.name == "Test Product"
      assert product.price == 100
    end

    test "allows nil values for optional fields" do
      attrs = %{
        name: "Test Product",
        price: 100
      }

      changeset = Product.changeset(%Product{}, attrs)

      assert {:ok, product} = changeset |> Ecto.Changeset.apply_action(:test)
      assert is_nil(product.width)
      assert is_nil(product.density)
    end

    test "handles integer to decimal conversion for weight" do
      attrs = %{
        name: "Test Product",
        price: 100,
        weight: 100
      }

      changeset = Product.changeset(%Product{}, attrs)

      assert {:ok, product} = changeset |> Ecto.Changeset.apply_action(:test)
      assert is_decimal(product.weight)
    end
  end

  describe "changeset/2 with calculations" do
    test "calculates density_for_count when all fields provided" do
      attrs = %{
        name: "Test Product",
        price: 100,
        weight_for_count: 500,
        length_for_count: 100,
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      # density_for_count = (500 / 100) / 150 * 100 = 3.33 -> 3
      assert is_decimal(changeset.changes[:density_for_count])
    end

    test "calculates meters_in_roll when all fields provided" do
      attrs = %{
        name: "Test Product",
        price: 100,
        weight: Decimal.new("1000"),
        density: 200,
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      # meters_in_roll = (1000 / 200) / 150 * 100000 = 3333.33
      assert is_decimal(changeset.changes[:meters_in_roll])
    end

    test "calculates prices from dollar_price and dollar_rate" do
      attrs = %{
        name: "Test Product",
        price: 100,
        dollar_price: Decimal.new("1.5"),
        dollar_rate: Decimal.new("90"),
        density: 200,
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      # prices should be a list of {coefficient, price} tuples
      assert is_list(changeset.changes[:prices])
      # Should have 10 price coefficients
      assert length(changeset.changes[:prices]) == 10
    end

    test "calculates density_for_count with zero length_for_count returns 0" do
      # Test with integer 0
      attrs_int = %{
        name: "Test Product",
        price: 100,
        weight_for_count: 500,
        length_for_count: 0,
        width: 150
      }

      changeset_int = Product.changeset(%Product{}, attrs_int)
      assert Decimal.equal?(changeset_int.changes[:density_for_count], Decimal.new(0))

      # Test with Decimal.new(0)
      attrs_decimal = %{
        name: "Test Product",
        price: 100,
        weight_for_count: 500,
        length_for_count: Decimal.new(0),
        width: 150
      }

      changeset_decimal = Product.changeset(%Product{}, attrs_decimal)
      assert Decimal.equal?(changeset_decimal.changes[:density_for_count], Decimal.new(0))
    end

    test "calculates density_for_count with nil values returns 0" do
      attrs = %{
        name: "Test Product",
        price: 100,
        weight_for_count: nil,
        length_for_count: 100,
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      assert Decimal.equal?(changeset.changes[:density_for_count], Decimal.new(0))
    end

    test "calculates meters_in_roll with zero density returns 0" do
      # Test with integer 0
      attrs_int = %{
        name: "Test Product",
        price: 100,
        weight: Decimal.new("1000"),
        density: 0,
        width: 150
      }

      changeset_int = Product.changeset(%Product{}, attrs_int)
      assert Decimal.equal?(changeset_int.changes[:meters_in_roll], Decimal.new(0))

      # Test with Decimal.new(0)
      attrs_decimal = %{
        name: "Test Product",
        price: 100,
        weight: Decimal.new("1000"),
        density: Decimal.new(0),
        width: 150
      }

      changeset_decimal = Product.changeset(%Product{}, attrs_decimal)
      assert Decimal.equal?(changeset_decimal.changes[:meters_in_roll], Decimal.new(0))
    end

    test "calculates meters_in_roll with zero width returns 0" do
      # Test with integer 0
      attrs_int = %{
        name: "Test Product",
        price: 100,
        weight: Decimal.new("1000"),
        density: 200,
        width: 0
      }

      changeset_int = Product.changeset(%Product{}, attrs_int)
      assert Decimal.equal?(changeset_int.changes[:meters_in_roll], Decimal.new(0))

      # Test with Decimal.new(0)
      attrs_decimal = %{
        name: "Test Product",
        price: 100,
        weight: Decimal.new("1000"),
        density: 200,
        width: Decimal.new(0)
      }

      changeset_decimal = Product.changeset(%Product{}, attrs_decimal)
      assert Decimal.equal?(changeset_decimal.changes[:meters_in_roll], Decimal.new(0))
    end

    test "calculates prices with nil dollar_price returns list with zeros" do
      attrs = %{
        name: "Test Product",
        price: 100,
        dollar_price: nil,
        dollar_rate: Decimal.new("90"),
        density: 200,
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      assert is_list(changeset.changes[:prices])
      # All prices should be 0 when dollar_price is nil
      Enum.each(changeset.changes[:prices], fn {_coeff, price} ->
        assert Decimal.equal?(price, Decimal.new(0))
      end)
    end

    test "handles partial calculation fields" do
      attrs = %{
        name: "Test Product",
        price: 100,
        width: 150
        # Missing density, dollar_price, etc.
      }

      changeset = Product.changeset(%Product{}, attrs)

      # Should still apply calculations without crashing
      assert %Ecto.Changeset{} = changeset
    end
  end

  describe "changeset/3 with image path" do
    test "sets image from path when provided as third argument" do
      attrs = %{
        name: "Test Product",
        price: 100
      }

      changeset = Product.changeset(%Product{}, attrs, ["uploads/image.jpg"])

      assert {:ok, product} = changeset |> Ecto.Changeset.apply_action(:test)
      assert product.image == "uploads/image.jpg"
    end

    test "sets image from path even with invalid other attrs" do
      attrs = %{
        price: 100
        # Missing name
      }

      changeset = Product.changeset(%Product{}, attrs, ["uploads/image.jpg"])

      # Image should be set but validation should still fail
      assert changeset.changes[:image] == "uploads/image.jpg"
      assert {:error, _changeset} = changeset |> Ecto.Changeset.apply_action(:test)
    end
  end

  describe "Calculation module delegation" do
    test "delegates calculation to Calculation module" do
      attrs = %{
        name: "Test Product",
        price: 100,
        weight_for_count: 500,
        length_for_count: 100,
        width: 150,
        weight: Decimal.new("1000"),
        density: 200,
        dollar_price: Decimal.new("1.5"),
        dollar_rate: Decimal.new("90")
      }

      changeset = Product.changeset(%Product{}, attrs)

      # All calculated fields should be present
      assert is_decimal(changeset.changes[:density_for_count])
      assert is_decimal(changeset.changes[:meters_in_roll])
      assert is_list(changeset.changes[:prices])
    end
  end

  describe "edge cases and validations" do
    test "handles Decimal precision in calculations" do
      attrs = %{
        name: "Test Product",
        price: 100,
        weight_for_count: Decimal.new("500.5"),
        length_for_count: Decimal.new("100.25"),
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      assert is_decimal(changeset.changes[:density_for_count])
    end

    test "handles negative weight_for_count" do
      attrs = %{
        name: "Test Product",
        price: 100,
        weight_for_count: -500,
        length_for_count: 100,
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      # Should not crash, will calculate negative density
      assert %Ecto.Changeset{} = changeset
    end

    test "handles very large values" do
      attrs = %{
        name: "Test Product",
        price: 100,
        weight_for_count: 1_000_000,
        length_for_count: 100,
        width: 150,
        weight: 1_000_000,
        density: 200,
        dollar_price: Decimal.new(1000),
        dollar_rate: Decimal.new(100)
      }

      changeset = Product.changeset(%Product{}, attrs)

      # Should handle large values without overflow
      assert is_decimal(changeset.changes[:density_for_count])
      assert is_decimal(changeset.changes[:meters_in_roll])
    end

    test "handles empty string name" do
      attrs = %{
        name: "",
        price: 100
      }

      changeset = Product.changeset(%Product{}, attrs)

      # Empty string should be allowed by validation (only :blank check)
      # But may fail at application level
      assert %Ecto.Changeset{} = changeset
    end

    test "handles zero price" do
      attrs = %{
        name: "Test Product",
        price: 0
      }

      assert {:error, changeset} =
               Product.changeset(%Product{}, attrs) |> Ecto.Changeset.apply_action(:test)

      assert %{price: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "handles all nil calculation fields" do
      attrs = %{
        name: "Test Product",
        price: 100
      }

      changeset = Product.changeset(%Product{}, attrs)

      assert is_decimal(changeset.changes[:density_for_count])
      assert is_decimal(changeset.changes[:meters_in_roll])
      assert is_list(changeset.changes[:prices])
    end
  end

  describe "foreign key constraint" do
    test "prevents deletion if order items exist" do
      product = ProductsFixtures.product_fixture()
      OrdersFixtures.order_item_fixture(%{product_id: product.id})

      # When product has order items, delete should fail due to foreign key constraint
      assert {:error, %Ecto.Changeset{} = changeset} = Products.delete_product(product)
      assert changeset.action == :delete

      assert "Cannot delete product: it has associated order items" in errors_on(changeset).order_items
    end

    test "allows deletion if no order items exist" do
      product = ProductsFixtures.product_fixture()

      # When product has no order items, delete should succeed
      assert {:ok, %Product{}} = Products.delete_product(product)
    end

    test "allows update without deleting" do
      product = ProductsFixtures.product_fixture()

      attrs = %{name: "Updated Name"}
      changeset = Product.changeset(product, attrs)

      assert changeset.valid?
      assert changeset.changes[:name] == "Updated Name"
    end
  end

  describe "price coefficients" do
    test "generates correct number of price coefficients" do
      attrs = %{
        name: "Test Product",
        price: 100,
        dollar_price: Decimal.new("1.5"),
        dollar_rate: Decimal.new("90"),
        density: 200,
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      prices = changeset.changes[:prices]

      # Should have exactly 10 coefficients: 1, 1.2, 1.3, ..., 2
      assert length(prices) == 10
    end

    test "price coefficients are in ascending order" do
      attrs = %{
        name: "Test Product",
        price: 100,
        dollar_price: Decimal.new("1.5"),
        dollar_rate: Decimal.new("90"),
        density: 200,
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      prices = changeset.changes[:prices]
      coeffs = Enum.map(prices, &elem(&1, 0))

      assert coeffs == [1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2]
    end

    test "higher coefficients result in higher prices" do
      attrs = %{
        name: "Test Product",
        price: 100,
        dollar_price: Decimal.new("1.5"),
        dollar_rate: Decimal.new("90"),
        density: 200,
        width: 150
      }

      changeset = Product.changeset(%Product{}, attrs)

      prices = changeset.changes[:prices]

      price_1 = Enum.at(prices, 0) |> elem(1)
      price_2 = Enum.at(prices, 9) |> elem(1)

      assert Decimal.compare(price_2, price_1) == :gt
    end
  end

  describe "JSON encoding" do
    test "excludes timestamps from encoding" do
      attrs = %{name: "Test Product", price: 100}
      changeset = Product.changeset(%Product{}, attrs)
      {:ok, product} = changeset |> Ecto.Changeset.apply_action(:insert)
      decoded = Jason.encode!(product) |> Jason.decode!()

      refute Map.has_key?(decoded, "inserted_at")
      refute Map.has_key?(decoded, "updated_at")
      assert decoded["name"] == "Test Product"
      assert decoded["price"] == 100
      assert decoded["id"] == product.id
    end

    test "includes only specified fields" do
      attrs = %{name: "Product", price: 200, width: 150, density: 100}
      changeset = Product.changeset(%Product{}, attrs)
      {:ok, product} = changeset |> Ecto.Changeset.apply_action(:insert)
      decoded = Jason.encode!(product) |> Jason.decode!()

      assert Map.has_key?(decoded, "id")
      assert Map.has_key?(decoded, "name")
      assert Map.has_key?(decoded, "price")
      refute Map.has_key?(decoded, "__meta__")
      refute Map.has_key?(decoded, "__struct__")
    end
  end
end
