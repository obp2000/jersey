defmodule Jersey.UtilsTest do
  use Jersey.DataCase
  alias Jersey.Utils

  describe "maybe_decode_live_select_value/3" do
    test "returns attrs unchanged when field is nil" do
      attrs = %{"other_field" => "value"}
      result = Utils.maybe_decode_live_select_value(attrs, "product")
      assert result == attrs
    end

    test "returns attrs unchanged when field is empty string" do
      attrs = %{"product" => "", "other_field" => "value"}
      result = Utils.maybe_decode_live_select_value(attrs, "product")
      assert result == attrs
    end

    test "returns attrs unchanged when field is not a binary" do
      attrs = %{"product" => 123, "other_field" => "value"}
      result = Utils.maybe_decode_live_select_value(attrs, "product")
      assert result == attrs
    end

    test "decodes valid live select JSON string" do
      json_value = ~s({"id": 123, "name": "Test Product"})
      attrs = %{"product" => json_value, "other_field" => "value"}

      result = Utils.maybe_decode_live_select_value(attrs, "product")

      assert result == %{
               "other_field" => "value",
               "product" => %{id: 123, name: "Test Product"}
             }
    end

    test "handles nested JSON in live select value" do
      json_value = ~s({"id": 789, "details": {"category": "test"}})
      attrs = %{"product" => json_value}

      result = Utils.maybe_decode_live_select_value(attrs, "product")

      assert Map.has_key?(result, "product")
    end

    test "returns attrs unchanged when JSON doesn't have id field" do
      json_value = ~s({"name": "No ID Product"})
      attrs = %{"product" => json_value}
      result = Utils.maybe_decode_live_select_value(attrs, "product")
      assert result == attrs
    end

    test "handles atom keys in attrs" do
      json_value = ~s({"id": 123})
      attrs = %{product: json_value, other_field: "value"}
      result = Utils.maybe_decode_live_select_value(attrs, :product)
      # The field value gets atomized
      assert result == %{
               other_field: "value",
               product: %{id: 123}
             }
    end
  end

  describe "get_fields/2" do
    test "returns empty map for empty fields list" do
      # Use a simple changeset without data
      changeset = %Ecto.Changeset{}
      result = Utils.get_fields(changeset, [])
      assert result == %{}
    end

    test "extracts single field from changeset" do
      # Create changeset with a map and types
      changeset = %Ecto.Changeset{
        changes: %{name: "test", age: 25},
        types: %{name: :string, age: :integer}
      }

      result = Utils.get_fields(changeset, [:name])
      assert result == %{name: "test"}
    end

    test "extracts multiple fields from changeset" do
      changeset = %Ecto.Changeset{
        changes: %{name: "test", age: 25, email: "test@example.com"},
        types: %{name: :string, age: :integer, email: :string}
      }

      result = Utils.get_fields(changeset, [:name, :age])
      assert result == %{name: "test", age: 25}
    end

    test "returns nil for fields with no changes" do
      changeset = %Ecto.Changeset{
        changes: %{name: "test", age: nil},
        types: %{name: :string, age: :integer}
      }

      result = Utils.get_fields(changeset, [:name, :age])
      assert result == %{name: "test", age: nil}
    end

    test "extracts all requested fields" do
      changeset = %Ecto.Changeset{
        changes: %{
          field1: "value1",
          field2: "value2",
          field3: "value3",
          field4: "value4"
        },
        types: %{
          field1: :string,
          field2: :string,
          field3: :string,
          field4: :string
        }
      }

      result = Utils.get_fields(changeset, [:field1, :field2, :field3, :field4])

      assert result == %{
               field1: "value1",
               field2: "value2",
               field3: "value3",
               field4: "value4"
             }
    end
  end
end
