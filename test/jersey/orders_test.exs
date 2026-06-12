defmodule Jersey.OrdersTest do
  use Jersey.DataCase

  alias Jersey.{Orders, Customers}
  alias Orders.{Order, OrderItem}
  alias Customers.{Customer, City}
  alias Ecto.{NoResultsError, Changeset}
  import Jersey.{OrdersFixtures, CustomersFixtures, ProductsFixtures}

  describe "orders" do
    @invalid_attrs %{}

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Orders.list_orders() == [order]
    end

    test "list_orders/0 returns orders ordered by desc id" do
      _order1 = order_fixture(%{address: "First Address"})
      order2 = order_fixture(%{address: "Second Address"})
      [loaded_order | _rest] = orders = Orders.list_orders()
      # Should have both orders
      assert length(orders) >= 2
      assert loaded_order == order2
    end

    test "list_orders/0 preloads customer and city associations" do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})
      order_fixture(%{customer_id: customer.id})
      [loaded_order] = Orders.list_orders()
      assert %Customer{} = loaded_order.customer
      assert %City{} = loaded_order.customer.city
    end

    test "list_orders/0 preloads order_items and products" do
      customer = customer_fixture()
      product = product_fixture(%{name: "Test Product", price: 100})
      order = order_fixture(%{customer_id: customer.id})

      {:ok, _item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      [loaded_order] = Orders.list_orders()

      assert length(loaded_order.order_items) == 1
      assert hd(loaded_order.order_items).product.id == product.id
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Orders.get_order!(order.id) == order
    end

    test "get_order!/1 preloads customer and city" do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})
      order = order_fixture(%{customer_id: customer.id})
      loaded_order = Orders.get_order!(order.id)
      assert %Customer{} = loaded_order.customer
      assert %City{} = loaded_order.customer.city
    end

    test "get_order!/1 preloads order_items and products" do
      customer = customer_fixture()
      product = product_fixture(%{name: "Test Product", price: 100})
      order = order_fixture(%{customer_id: customer.id})

      {:ok, _item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      loaded_order = Orders.get_order!(order.id)
      assert length(loaded_order.order_items) == 1
      assert hd(loaded_order.order_items).product.id == product.id
    end

    test "get_order!/1 raises when order not found" do
      assert_raise NoResultsError, fn -> Orders.get_order!(99999) end
    end

    test "create_order/1 with valid data creates a order" do
      customer = customer_fixture()
      valid_attrs = %{customer: %{id: customer.id}, address: "some address"}

      assert {:ok, %Order{} = order} = Orders.create_order(valid_attrs)
      assert order.address == "some address"
      assert order.customer_id != nil
    end

    test "create_order/1 with full attributes creates order" do
      customer = customer_fixture()

      valid_attrs = %{
        customer: %{id: customer.id},
        address: "Test Address",
        delivery_type: :pochta,
        packet: 25
      }

      assert {:ok, %Order{} = order} = Orders.create_order(valid_attrs)
      assert order.delivery_type == :pochta
      assert order.packet == 25
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, changeset} = Orders.create_order(@invalid_attrs)
      refute changeset.valid?
    end

    test "create_order/1 requires customer" do
      assert {:error, changeset} = Orders.create_order(%{address: "test"})
      refute changeset.valid?
    end

    test "update_order/2 updates multiple fields" do
      customer = customer_fixture()
      order = order_fixture(%{customer_id: customer.id})

      update_attrs = %{
        address: "Updated Address",
        delivery_type: :delovie,
        packet: 25
      }

      assert {:ok, updated_order} = Orders.update_order(order, update_attrs)
      assert updated_order.address == "Updated Address"
      assert updated_order.delivery_type == :delovie
      assert updated_order.packet == 25
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      update_attrs = %{address: "some updated address"}

      assert {:ok, %Order{} = order} = Orders.update_order(order, update_attrs)
      assert order.address == "some updated address"
    end

    test "update_order/2 with blank data does not change order" do
      order = order_fixture()
      returned = Orders.get_order!(order.id)
      assert {:ok, updated_order} = Orders.update_order(order, %{})
      assert returned.id == updated_order.id
      assert returned.customer_id == updated_order.customer_id
      assert returned.address == updated_order.address
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Orders.delete_order(order)
      assert_raise NoResultsError, fn -> Orders.get_order!(order.id) end
    end

    test "delete_order/1 cascades to order_items" do
      customer = customer_fixture()
      product = product_fixture(%{name: "Test Product", price: 100})
      order = order_fixture(%{customer_id: customer.id})

      {:ok, item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      assert {:ok, _} = Orders.delete_order(order)

      # Order item should also be deleted
      assert_raise NoResultsError, fn -> Orders.get_order_item!(item.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Changeset{} = Orders.change_order(order)
    end

    test "change_order/2 with attrs returns changeset with changes" do
      order = order_fixture()
      changeset = Orders.change_order(order, %{address: "New Address"})

      assert get_change(changeset, :address) == "New Address"
    end
  end

  describe "order_items" do
    @invalid_attrs %{amount: nil, price: nil}

    test "list_order_items/0 returns all order_items" do
      customer = customer_fixture()
      product = product_fixture(%{name: "Test Product", price: 100})
      order = order_fixture(%{customer_id: customer.id})

      {:ok, item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      items = Orders.list_order_items()
      assert length(items) == 1
      assert Enum.find(items, &(&1.id == item.id))
    end

    test "get_order_item!/1 returns the order_item with given id" do
      customer = customer_fixture()
      product = product_fixture(%{name: "Test Product", price: 100})
      order = order_fixture(%{customer_id: customer.id})

      {:ok, item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      loaded_item = Orders.get_order_item!(item.id)
      assert loaded_item.id == item.id
      assert loaded_item.amount == item.amount
      assert loaded_item.price == item.price
    end

    test "get_order_item!/1 raises when not found" do
      assert_raise NoResultsError, fn -> Orders.get_order_item!(99999) end
    end

    test "create_order_item/1 with valid data creates a order_item" do
      customer = customer_fixture()
      product = product_fixture(%{name: "Test Product", price: 100})
      order = order_fixture(%{customer_id: customer.id})

      valid_attrs = %{
        order_id: order.id,
        product_id: product.id,
        amount: Decimal.new("2"),
        price: Decimal.new("200")
      }

      assert {:ok, %OrderItem{} = item} = Orders.create_order_item(valid_attrs)
      assert item.amount == Decimal.new("2")
      assert item.price == Decimal.new("200")
    end

    test "create_order_item/1 with invalid data returns error changeset" do
      assert {:error, %Changeset{}} = Orders.create_order_item(@invalid_attrs)
    end

    test "create_order_item/1 requires amount and price > 0" do
      customer = customer_fixture()
      product = product_fixture()
      order = order_fixture(%{customer_id: customer.id})

      invalid_attrs = %{
        order_id: order.id,
        product_id: product.id,
        amount: Decimal.new("0"),
        price: Decimal.new("-1")
      }

      assert {:error, %Changeset{}} = Orders.create_order_item(invalid_attrs)
    end

    test "update_order_item/2 with valid data updates the order_item" do
      customer = customer_fixture()
      product = product_fixture(%{name: "Test Product", price: 100})
      order = order_fixture(%{customer_id: customer.id})

      {:ok, item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      item = Orders.get_order_item!(item.id)
      update_attrs = %{amount: Decimal.new("5"), price: Decimal.new("500")}

      assert {:ok, updated_item} = Orders.update_order_item(item, update_attrs)
      assert updated_item.amount == Decimal.new("5")
      assert updated_item.price == Decimal.new("500")
    end

    test "update_order_item/2 with invalid data returns error changeset" do
      customer = customer_fixture()
      product = product_fixture()
      order = order_fixture(%{customer_id: customer.id})

      {:ok, item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      item = Orders.get_order_item!(item.id)
      invalid_attrs = %{amount: Decimal.new("0")}

      assert {:error, %Changeset{}} = Orders.update_order_item(item, invalid_attrs)
    end

    test "delete_order_item/1 deletes the order_item" do
      customer = customer_fixture()
      product = product_fixture()
      order = order_fixture(%{customer_id: customer.id})

      {:ok, item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      assert {:ok, %OrderItem{}} = Orders.delete_order_item(item)
      assert_raise NoResultsError, fn -> Orders.get_order_item!(item.id) end
    end

    test "change_order_item/1 returns a order_item changeset" do
      customer = customer_fixture()
      product = product_fixture()
      order = order_fixture(%{customer_id: customer.id})

      {:ok, item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      item = Orders.get_order_item!(item.id)
      assert %Changeset{} = Orders.change_order_item(item)
    end

    test "change_order_item/2 with attrs returns changeset" do
      customer = customer_fixture()
      product = product_fixture()
      order = order_fixture(%{customer_id: customer.id})

      {:ok, item} =
        Orders.create_order_item(%{
          order_id: order.id,
          product_id: product.id,
          amount: Decimal.new("1"),
          price: Decimal.new("100")
        })

      item = Orders.get_order_item!(item.id)
      changeset = Orders.change_order_item(item, %{amount: Decimal.new("5")})
      assert get_change(changeset, :amount) == Decimal.new("5")
    end
  end

  describe "delegations" do
    test "search_customers delegates to Customers" do
      customer_fixture(%{nick: "test_search", name: "Test"})

      results = Orders.search_customers("test")

      assert length(results) == 1
    end

    test "full_customer_name delegates to Customers" do
      customer = customer_fixture(%{nick: "nick", name: "Name", address: "Address"})

      full_name = Orders.full_customer_name(customer)

      assert full_name =~ "nick"
      assert full_name =~ "Name"
    end

    test "get_customer! delegates to Customers" do
      customer = customer_fixture()

      assert Orders.get_customer!(customer.id).id == customer.id
    end

    test "search_products delegates to Products" do
      product_fixture(%{name: "Test Product"})

      results = Orders.search_products("test")

      assert length(results) == 1
    end

    test "get_product! delegates to Products" do
      product = product_fixture()

      assert Orders.get_product!(product.id).id == product.id
    end

    test "set_post_cost_if_possible delegates to Order" do
      customer = customer_fixture()
      order = order_fixture(%{customer_id: customer.id})

      changeset = Orders.change_order(order)
      result = Orders.set_post_cost_if_possible(changeset)

      assert %Changeset{} = result
    end
  end
end
