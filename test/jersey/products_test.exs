defmodule Jersey.ProductsTest do
  use Jersey.DataCase

  alias Jersey.Products

  describe "products" do
    alias Jersey.Products.Product

    import Jersey.ProductsFixtures

    @invalid_attrs %{name: nil, price: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      [loaded] = Products.list_products()

      assert loaded.id == product.id
      assert loaded.name == product.name
      assert loaded.price == product.price
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      loaded = Products.get_product!(product.id)

      assert loaded.id == product.id
      assert loaded.name == product.name
      assert loaded.price == product.price
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{name: "some name", price: 42}

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.name == "some name"
      assert product.price == 42

    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{name: "some updated name", price: 43}

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.name == "some updated name"
      assert product.price == 43
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, @invalid_attrs)

      loaded = Products.get_product!(product.id)
      assert loaded.id == product.id
      assert loaded.name == product.name
      assert loaded.price == product.price
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Products.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Products.change_product(product)
    end
  end
end
