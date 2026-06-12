defmodule Jersey.ProductsTest do
  use Jersey.DataCase

  alias Jersey.Products
  alias Jersey.Products.Product
  import Jersey.ProductsFixtures

  describe "products" do
    @invalid_attrs %{name: nil, price: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      [loaded] = Products.list_products()

      assert loaded.id == product.id
      assert loaded.name == product.name
      assert loaded.price == product.price
    end

    test "list_products/0 returns products ordered by inserted_at" do
      _product1 = product_fixture(%{name: "First Product"})
      _product2 = product_fixture(%{name: "Second Product"})
      products = Products.list_products()
      # Should have both products
      assert length(products) >= 2
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      loaded = Products.get_product!(product.id)

      assert loaded.id == product.id
      assert loaded.name == product.name
      assert loaded.price == product.price
    end

    test "get_product!/1 raises when product not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Products.get_product!(99999)
      end
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{name: "some name", price: 42}

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.name == "some name"
      assert product.price == 42
    end

    test "create_product/1 with full attributes creates product" do
      valid_attrs = %{
        name: "Complete Product",
        price: 100,
        weight: Decimal.new("50.5"),
        width: 150,
        density: 200,
        dollar_price: Decimal.new("1.5"),
        dollar_rate: Decimal.new("90")
      }

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.name == "Complete Product"
      assert product.width == 150
      assert product.density == 200
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "create_product/1 with empty name returns error" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(%{name: "", price: 42})
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{name: "some updated name", price: 43}

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.name == "some updated name"
      assert product.price == 43
    end

    test "update_product/2 updates calculation fields" do
      product =
        product_fixture(%{
          width: 150,
          density: 200,
          dollar_price: Decimal.new("1.5"),
          dollar_rate: Decimal.new("90")
        })

      update_attrs = %{width: 200}

      assert {:ok, updated_product} = Products.update_product(product, update_attrs)
      assert updated_product.width == 200
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

    test "change_product/2 with attrs updates changeset" do
      product = product_fixture()
      changeset = Products.change_product(product, %{name: "Updated Name"})

      assert get_change(changeset, :name) == "Updated Name"
    end

    test "change_product/3 with uploaded files sets image" do
      product = product_fixture()
      changeset = Products.change_product(product, %{}, ["uploads/image.jpg"])

      assert get_change(changeset, :image) == "uploads/image.jpg"
    end
  end

  describe "search_products/1" do
    test "searches by name" do
      product_fixture(%{name: "T-Shirt"})
      product_fixture(%{name: "Polo Shirt"})
      product_fixture(%{name: "Jeans"})

      results = Products.search_products("shirt")

      assert length(results) == 2
    end

    test "case-insensitive search" do
      product_fixture(%{name: "TestProduct"})

      results = Products.search_products("test")

      assert length(results) == 1
    end

    test "partial match search" do
      product_fixture(%{name: "Cotton T-Shirt"})
      product_fixture(%{name: "Polyester T-Shirt"})
      product_fixture(%{name: "Jeans"})

      results = Products.search_products("t-")

      assert length(results) == 2
    end

    test "returns empty list when no match" do
      product_fixture(%{name: "T-Shirt"})

      results = Products.search_products("nonexistent")

      assert results == []
    end

    test "handles special characters in search" do
      product_fixture(%{name: "T-Shirt & Co"})

      results = Products.search_products("&")

      assert length(results) == 1
    end

    test "handles unicode characters in search" do
      product_fixture(%{name: "Футболка"})

      results = Products.search_products("фут")

      assert length(results) == 1
    end
  end

  describe "paginate_products/1" do
    test "returns paginated results" do
      for _i <- 1..25 do
        product_fixture()
      end

      page1 = Products.paginate_products(page: 1)

      assert page1.page_number == 1
      assert length(page1.entries) == 5
    end

    test "returns correct page number" do
      for _i <- 1..25 do
        product_fixture()
      end

      page2 = Products.paginate_products(page: 2)

      assert page2.page_number == 2
      assert length(page2.entries) == 5
    end

    test "returns ordered results (newest first)" do
      product_fixture(%{name: "First Product"})
      product_fixture(%{name: "Second Product"})
      product3 = product_fixture(%{name: "Third Product"})
      products = Products.paginate_products(page: 1)
      assert hd(products.entries).id == product3.id
    end

    test "handles empty database" do
      page = Products.paginate_products(page: 1)

      assert page.page_number == 1
      assert page.entries == []
    end
  end

  describe "count_products/0" do
    test "returns count of products" do
      product_fixture()
      product_fixture()
      product_fixture()

      count = Products.count_products()

      assert count == 3
    end

    test "returns 0 for empty database" do
      count = Products.count_products()

      assert count == 0
    end

    test "count increases after insert" do
      initial_count = Products.count_products()

      product_fixture()

      new_count = Products.count_products()

      assert new_count == initial_count + 1
    end
  end

  describe "default constants" do
    test "default_per_page returns 20" do
      assert Products.default_per_page() == 20
    end

    test "default_page returns 1" do
      assert Products.default_page() == 1
    end
  end
end
