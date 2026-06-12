defmodule Jersey.Orders.OrderItemTest do
  use Jersey.DataCase
  alias Jersey.{Orders, Products.Product, ProductsFixtures, OrdersFixtures}
  alias Orders.{OrderItem, Order, Order.Calculation}

  describe "schema" do
    test "has correct fields" do
      fields = OrderItem.__schema__(:fields)

      assert :amount in fields
      assert :price in fields
      assert :order_id in fields
      assert :product_id in fields
    end

    test "has correct virtual fields" do
      virtual_fields = OrderItem.__schema__(:virtual_fields)
      assert :order_item_price in virtual_fields
      assert :order_item_weight in virtual_fields
    end

    test "has correct associations" do
      order_assoc = OrderItem.__schema__(:association, :order)
      product_assoc = OrderItem.__schema__(:association, :product)

      assert order_assoc.related == Order
      assert product_assoc.related == Product
      assert product_assoc.on_replace == :nilify
    end

    test "has timestamps" do
      fields = OrderItem.__schema__(:fields)

      assert :inserted_at in fields
      assert :updated_at in fields
    end
  end

  describe "base_changeset/2" do
    test "requires amount and price and validates they are > 0" do
      cs = OrderItem.base_changeset(%OrderItem{}, %{amount: 0, price: -1})
      assert {:error, _} = Ecto.Changeset.apply_action(cs, :test)

      assert %{
               amount: ["must be greater than 0"],
               price: ["must be greater than 0"]
             } = errors_on(cs)
    end

    test "accepts valid amount and price" do
      cs =
        OrderItem.base_changeset(%OrderItem{}, %{
          amount: Decimal.new("10"),
          price: Decimal.new("100")
        })

      assert cs.valid?
    end

    test "accepts integer amount and price" do
      cs =
        OrderItem.base_changeset(%OrderItem{}, %{
          amount: 10,
          price: 100
        })

      assert cs.valid?
    end

    test "rejects nil amount" do
      cs = OrderItem.base_changeset(%OrderItem{}, %{amount: nil, price: 100})

      assert {:error, _} = Ecto.Changeset.apply_action(cs, :test)
      assert %{amount: ["can't be blank"]} = errors_on(cs)
    end

    test "rejects nil price" do
      cs = OrderItem.base_changeset(%OrderItem{}, %{amount: 10, price: nil})

      assert {:error, _} = Ecto.Changeset.apply_action(cs, :test)
      assert %{price: ["can't be blank"]} = errors_on(cs)
    end
  end

  describe "changeset/2" do
    setup do
      order = OrdersFixtures.order_fixture()

      product =
        ProductsFixtures.product_fixture(%{
          density: 200,
          width: 150,
          dollar_price: Decimal.new("1.5"),
          dollar_rate: Decimal.new("90")
        })

      %{order: order, product: product}
    end

    test "calculates order_item_price and order_item_weight when product association is loaded",
         %{
           order: order,
           product: product
         } do
      attrs = %{
        amount: Decimal.new("10"),
        price: Decimal.new("100"),
        # Ecto associate setters expect structs
        order: order,
        product: %{
          id: product.id,
          name: product.name,
          price: product.price,
          density: product.density,
          width: product.width,
          # fields required by Product.changeset/2 casting pipeline
          dollar_price: product.dollar_price,
          dollar_rate: product.dollar_rate
        }
      }

      cs = OrderItem.changeset(%OrderItem{}, attrs)

      assert cs.valid?
      # price is taken from product.price (42), so 10 * 42 = 420
      expected_price = Calculation.order_item_price(Decimal.new("10"), Decimal.new("310"))
      assert cs.changes.order_item_price == expected_price

      expected_weight =
        Decimal.new("10")
        |> Decimal.mult(product.density)
        |> Decimal.mult(product.width)
        |> Decimal.div(Decimal.new("100"))
        |> Decimal.round(0)

      assert cs.changes.order_item_weight == expected_weight
    end

    test "updates price from product when product price changes", %{
      order: order,
      product: product
    } do
      attrs = %{
        amount: Decimal.new("10"),
        price: Decimal.new("100"),
        order: order,
        product: %{
          id: product.id,
          name: product.name,
          price: 200,
          density: product.density,
          width: product.width,
          dollar_price: product.dollar_price,
          dollar_rate: product.dollar_rate
        }
      }

      cs = OrderItem.changeset(%OrderItem{}, attrs)

      assert cs.valid?
      # Price should be updated from product
      assert Decimal.equal?(cs.changes.price, Decimal.new(200))
    end

    test "does not crash and returns weight 0 when product association is missing", %{
      order: order
    } do
      cs =
        OrderItem.changeset(%OrderItem{order_id: order.id}, %{
          order_id: order.id,
          amount: Decimal.new("1"),
          price: Decimal.new("2")
        })

      assert cs.valid?
      assert cs.changes.order_item_weight == Decimal.new(0)
    end

    test "calculates weight with zero when product is nil" do
      cs =
        OrderItem.changeset(%OrderItem{}, %{
          amount: Decimal.new("10"),
          price: Decimal.new("100")
        })

      assert cs.changes.order_item_weight == Decimal.new(0)
    end

    test "handles decimal precision in calculations", %{
      order: order,
      product: product
    } do
      attrs = %{
        amount: Decimal.new("10.5"),
        price: Decimal.new("100.25"),
        order: order,
        product: %{
          id: product.id,
          name: product.name,
          price: product.price,
          density: product.density,
          width: product.width,
          dollar_price: product.dollar_price,
          dollar_rate: product.dollar_rate
        }
      }

      cs = OrderItem.changeset(%OrderItem{}, attrs)

      assert cs.valid?
      # price is taken from product.price (42), so 10.5 * 42 = 441
      expected_price = Calculation.order_item_price(Decimal.new("10.5"), Decimal.new("310"))
      assert cs.changes.order_item_price == expected_price
    end
  end

  describe "save_changeset/2" do
    setup do
      order = OrdersFixtures.order_fixture()

      product =
        ProductsFixtures.product_fixture(%{
          density: 200,
          width: 150,
          dollar_price: Decimal.new("1.5"),
          dollar_rate: Decimal.new("90")
        })

      %{order: order, product: product}
    end

    test "syncs product_id from LiveSelect product map when product_id differs", %{
      order: order,
      product: product
    } do
      # When product is passed as a map (already decoded from LiveSelect)
      cs =
        OrderItem.save_changeset(
          %OrderItem{order_id: order.id, product_id: 99999},
          %{
            "order_id" => order.id,
            "product" => %{id: product.id},
            "amount" => "1",
            "price" => "2"
          }
        )

      assert cs.valid?
      assert Ecto.Changeset.get_change(cs, :product_id) == product.id
    end

    test "does not change product_id when LiveSelect product id matches existing product_id", %{
      order: order,
      product: product
    } do
      cs =
        OrderItem.save_changeset(
          %OrderItem{order_id: order.id, product_id: product.id},
          %{
            "order_id" => order.id,
            "product" => %{id: product.id},
            "amount" => "1",
            "price" => "2"
          }
        )

      assert cs.valid?
      refute Ecto.Changeset.get_change(cs, :product_id)
    end

    test "handles nil product in attrs" do
      cs =
        OrderItem.save_changeset(
          %OrderItem{},
          %{
            "order_id" => 1,
            "product" => nil
          }
        )

      assert %Ecto.Changeset{} = cs
    end

    test "handles empty product map" do
      cs =
        OrderItem.save_changeset(
          %OrderItem{},
          %{
            "order_id" => 1,
            "product" => %{}
          }
        )

      assert %Ecto.Changeset{} = cs
    end

    test "accepts valid amount and price as strings" do
      cs =
        OrderItem.save_changeset(
          %OrderItem{},
          %{
            "order_id" => 1,
            "amount" => "10",
            "price" => "100"
          }
        )

      assert cs.valid?
    end

    test "validates foreign_key_constraint for product_id" do
      order = OrdersFixtures.order_fixture()

      cs =
        OrderItem.save_changeset(%OrderItem{}, %{
          order_id: order.id,
          product_id: 99999,
          amount: 10,
          price: 100
        })

      assert cs.valid?
      assert {:error, changeset} = Repo.insert(cs)

      assert changeset.errors[:product_id] == {
               "does not exist",
               [constraint: :foreign, constraint_name: "order_items_product_id_fkey"]
             }
    end

    test "validates foreign_key_constraint for order_id" do
      cs =
        OrderItem.save_changeset(%OrderItem{}, %{
          order_id: 99999,
          amount: 10,
          price: 100
        })

      assert cs.valid?
      assert {:error, changeset} = Repo.insert(cs)

      assert changeset.errors[:order_id] == {
               "does not exist",
               [constraint: :foreign, constraint_name: "order_items_order_id_fkey"]
             }
    end

    test "enforces unique constraint on [:order_id, :product_id]" do
      order_item = OrdersFixtures.order_item_fixture()

      # Second insert with same order_id and product_id should fail
      assert {:error, %Ecto.Changeset{}} =
               Orders.create_order_item(%{
                 order_id: order_item.order_id,
                 product_id: order_item.product_id,
                 amount: Decimal.new("3"),
                 price: Decimal.new("4")
               })
    end
  end

  describe "Calculation module functions" do
    test "order_item_price calculates correctly" do
      price = Calculation.order_item_price(Decimal.new("10"), Decimal.new("100"))

      assert Decimal.equal?(price, Decimal.new("1000"))
    end

    test "order_item_price returns 0 when amount is nil" do
      price = Calculation.order_item_price(nil, Decimal.new("100"))

      assert price == Decimal.new(0)
    end

    test "order_item_price returns 0 when price is nil" do
      price = Calculation.order_item_price(Decimal.new("10"), nil)

      assert price == Decimal.new(0)
    end

    test "order_item_weight calculates correctly" do
      product = %{density: 200, width: 150}
      weight = Calculation.order_item_weight(Decimal.new("10"), product)

      # 10 * 200 * 150 / 100 = 3000
      assert weight == Decimal.new(3000)
    end

    test "order_item_weight returns 0 when amount is nil" do
      product = %{density: 200, width: 150}
      weight = Calculation.order_item_weight(nil, product)

      assert weight == Decimal.new(0)
    end

    test "order_item_weight returns 0 when product is nil" do
      weight = Calculation.order_item_weight(Decimal.new("10"), nil)

      assert weight == Decimal.new(0)
    end

    test "order_item_weight returns 0 when density is nil" do
      product = %{density: nil, width: 150}
      weight = Calculation.order_item_weight(Decimal.new("10"), product)

      assert weight == Decimal.new(0)
    end

    test "order_item_weight returns 0 when width is nil" do
      product = %{density: 200, width: nil}
      weight = Calculation.order_item_weight(Decimal.new("10"), product)

      assert weight == Decimal.new(0)
    end

    test "calculate_order_item returns both price and weight" do
      amount = Decimal.new("10")
      price = Decimal.new("100")
      product = %{density: 200, width: 150}

      result =
        Calculation.calculate_order_item(%{
          amount: amount,
          price: price,
          product: product
        })

      assert Decimal.equal?(result.order_item_price, Decimal.new("1000"))
      assert result.order_item_weight == Decimal.new(3000)
    end
  end

  describe "edge cases" do
    setup do
      order = OrdersFixtures.order_fixture()

      product =
        ProductsFixtures.product_fixture(%{
          name: "test product",
          price: 100,
          weight: Decimal.new("50"),
          width: 150,
          density: 200,
          dollar_price: Decimal.new("1.5"),
          dollar_rate: Decimal.new("90")
        })

      %{order: order, product: product}
    end

    test "handles very large amounts", %{order: order, product: product} do
      attrs = %{
        amount: Decimal.new("1000000"),
        price: Decimal.new("100"),
        order: order,
        product: %{
          id: product.id,
          name: product.name,
          price: product.price,
          density: product.density,
          width: product.width,
          dollar_price: product.dollar_price,
          dollar_rate: product.dollar_rate
        }
      }

      cs = OrderItem.changeset(%OrderItem{}, attrs)

      assert cs.valid?
      assert Decimal.equal?(cs.changes.order_item_price, Decimal.new("100000000"))
    end

    test "handles decimal amounts", %{order: order, product: product} do
      attrs = %{
        amount: Decimal.new("0.5"),
        price: Decimal.new("100"),
        order: order,
        product: %{
          id: product.id,
          name: product.name,
          price: product.price,
          density: product.density,
          width: product.width,
          dollar_price: product.dollar_price,
          dollar_rate: product.dollar_rate
        }
      }

      cs = OrderItem.changeset(%OrderItem{}, attrs)

      assert cs.valid?
      assert Decimal.equal?(cs.changes.order_item_price, Decimal.new("50"))
    end

    test "handles zero price", %{order: order, product: product} do
      attrs = %{
        amount: Decimal.new("10"),
        price: Decimal.new("0"),
        order: order,
        product: %{
          id: product.id,
          name: product.name,
          price: 0,
          density: product.density,
          width: product.width,
          dollar_price: product.dollar_price,
          dollar_rate: product.dollar_rate
        }
      }

      cs = OrderItem.changeset(%OrderItem{}, attrs)

      # price=0 is invalid (must be > 0)
      refute cs.valid?
      assert %{price: ["must be greater than 0"]} = errors_on(cs)
    end
  end
end
