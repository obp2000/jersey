defmodule Jersey.Customers.CityTest do
  use Jersey.DataCase

  alias Jersey.Customers.City

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
  end
end
