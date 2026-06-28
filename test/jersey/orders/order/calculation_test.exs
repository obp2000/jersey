defmodule Jersey.Orders.Order.CalculationTest do
  use Jersey.DataCase
  alias Jersey.Orders.Order.Calculation
  import Decimal, only: [new: 1]

  describe "gift_weight/0" do
    test "returns 100" do
      assert Calculation.gift_weight() == 100
    end
  end

  describe "samples_weight/0" do
    test "returns 50" do
      assert Calculation.samples_weight() == 50
    end
  end

  describe "packet_weight/0" do
    test "returns 50" do
      assert Calculation.packet_weight() == 50
    end
  end

  describe "order_item_price/2" do
    test "calculates price correctly when amount and price are provided" do
      result = Calculation.order_item_price(new("10"), new("100"))
      assert Decimal.equal?(result, new("1000"))
    end

    test "rounds to 2 decimal places" do
      result = Calculation.order_item_price(new("10.5"), new("100.25"))
      assert Decimal.equal?(result, new("1052.63"))
    end

    test "returns 0 when amount is nil" do
      result = Calculation.order_item_price(nil, new("100"))
      assert Decimal.equal?(result, new(0))
    end

    test "returns 0 when price is nil" do
      result = Calculation.order_item_price(new("10"), nil)
      assert Decimal.equal?(result, new(0))
    end

    test "returns 0 when both are nil" do
      result = Calculation.order_item_price(nil, nil)
      assert Decimal.equal?(result, new(0))
    end
  end

  describe "order_item_weight/2" do
    test "calculates weight correctly when all fields are provided" do
      product = %{density: 200, width: 150}
      result = Calculation.order_item_weight(new("10"), product)
      # 10 * 200 * 150 / 100 = 3000
      assert Decimal.equal?(result, new("3000"))
    end

    test "rounds to 0 decimal places" do
      product = %{density: 200, width: 150}
      result = Calculation.order_item_weight(new("10.5"), product)
      # 10.5 * 200 * 150 / 100 = 3150
      assert Decimal.equal?(result, new("3150"))
    end

    test "returns 0 when amount is nil" do
      product = %{density: 200, width: 150}
      result = Calculation.order_item_weight(nil, product)
      assert Decimal.equal?(result, new(0))
    end

    test "returns 0 when product is nil" do
      result = Calculation.order_item_weight(new("10"), nil)
      assert Decimal.equal?(result, new(0))
    end

    test "returns 0 when density is nil" do
      product = %{density: nil, width: 150}
      result = Calculation.order_item_weight(new("10"), product)
      assert Decimal.equal?(result, new(0))
    end

    test "returns 0 when width is nil" do
      product = %{density: 200, width: nil}
      result = Calculation.order_item_weight(new("10"), product)
      assert Decimal.equal?(result, new(0))
    end

    test "returns 0 when both density and width are nil" do
      product = %{density: nil, width: nil}
      result = Calculation.order_item_weight(new("10"), product)
      assert Decimal.equal?(result, new(0))
    end
  end

  describe "calculate_order_item/1" do
    test "calculates both price and weight" do
      product = %{density: 200, width: 150}

      result =
        Calculation.calculate_order_item(%{
          amount: new("10"),
          price: new("100"),
          product: product
        })

      assert Decimal.equal?(result.order_item_price, new("1000"))
      assert Decimal.equal?(result.order_item_weight, new("3000"))
    end

    test "handles nil amount" do
      product = %{density: 200, width: 150}

      result =
        Calculation.calculate_order_item(%{
          amount: nil,
          price: new("100"),
          product: product
        })

      assert Decimal.equal?(result.order_item_price, new(0))
      assert Decimal.equal?(result.order_item_weight, new(0))
    end

    test "handles nil product" do
      result =
        Calculation.calculate_order_item(%{
          amount: new("10"),
          price: new("100"),
          product: nil
        })

      assert Decimal.equal?(result.order_item_price, new("1000"))
      assert Decimal.equal?(result.order_item_weight, new(0))
    end

    test "handles nil price" do
      product = %{density: 200, width: 150}

      result =
        Calculation.calculate_order_item(%{
          amount: new("10"),
          price: nil,
          product: product
        })

      assert Decimal.equal?(result.order_item_price, new(0))
      assert Decimal.equal?(result.order_item_weight, new("3000"))
    end
  end

  describe "order_items_price/1" do
    test "returns 0 for empty list" do
      result = Calculation.order_items_price([])
      assert Decimal.equal?(result, new(0))
    end

    test "returns 0 for nil" do
      result = Calculation.order_items_price(nil)
      assert Decimal.equal?(result, new(0))
    end
  end

  describe "order_items_weight/1" do
    test "returns 0 for empty list" do
      result = Calculation.order_items_weight([])
      assert Decimal.equal?(result, new(0))
    end

    test "returns 0 for nil" do
      result = Calculation.order_items_weight(nil)
      assert Decimal.equal?(result, new(0))
    end
  end

  describe "need_gift?/1" do
    test "returns true when price is greater than 2000" do
      assert Calculation.need_gift?(new("2001")) == true
    end

    test "returns true when price is exactly 2000" do
      assert Calculation.need_gift?(new("2000")) == true
    end

    test "returns false when price is less than 2000" do
      assert Calculation.need_gift?(new("1999")) == false
    end

    test "returns false for 0" do
      assert Calculation.need_gift?(new(0)) == false
    end
  end

  describe "need_post_discount?/1" do
    test "returns true when price is greater than 1000" do
      assert Calculation.need_post_discount?(new("1001")) == true
    end

    test "returns true when price is exactly 1000" do
      assert Calculation.need_post_discount?(new("1000")) == true
    end

    test "returns false when price is less than 1000" do
      assert Calculation.need_post_discount?(new("999")) == false
    end

    test "returns false for 0" do
      assert Calculation.need_post_discount?(new(0)) == false
    end

    test "returns nil for nil input" do
      assert Calculation.need_post_discount?(nil) == nil
    end
  end

  describe "post_cost_with_packet/2" do
    test "adds packet to post_cost" do
      result = Calculation.post_cost_with_packet(new("500"), 25)
      assert Decimal.equal?(result, new("525"))
    end

    test "handles nil post_cost" do
      result = Calculation.post_cost_with_packet(nil, 25)
      assert Decimal.equal?(result, new("25"))
    end

    test "handles nil packet" do
      result = Calculation.post_cost_with_packet(new("500"), nil)
      assert Decimal.equal?(result, new("500"))
    end

    test "handles both nil" do
      result = Calculation.post_cost_with_packet(nil, nil)
      assert Decimal.equal?(result, new(0))
    end
  end

  describe "post_discount/1" do
    test "calculates 30% discount and rounds to 0 decimals" do
      result = Calculation.post_discount(new("525"))
      # 525 * 0.3 = 157.5 -> rounded to 158
      assert Decimal.equal?(result, new("158"))
    end

    test "calculates discount for larger values" do
      result = Calculation.post_discount(new("1000"))
      # 1000 * 0.3 = 300
      assert Decimal.equal?(result, new("300"))
    end
  end

  describe "total_post_cost/2" do
    test "subtracts post_discount from post_cost_with_packet" do
      result = Calculation.total_post_cost(new("525"), new("158"))
      # 525 - 158 = 367
      assert Decimal.equal?(result, new("367"))
    end

    test "returns post_cost_with_packet when post_discount is nil" do
      result = Calculation.total_post_cost(new("525"), nil)
      assert Decimal.equal?(result, new("525"))
    end
  end

  describe "total_price/2" do
    test "adds order_items_price and total_post_cost" do
      result = Calculation.total_price(new("2000"), new("367"))
      # 2000 + 367 = 2367
      assert Decimal.equal?(result, new("2367"))
    end

    test "handles zero values" do
      result = Calculation.total_price(new(0), new(0))
      assert Decimal.equal?(result, new(0))
    end
  end

  describe "total_weight/2" do
    test "calculates weight with packet, samples, and gift when needed" do
      result = Calculation.total_weight(new("3000"), true)
      # 3000 + 50 (packet) + 50 (samples) + 100 (gift) = 3200
      assert Decimal.equal?(result, new("3200"))
    end

    test "calculates weight without gift when not needed" do
      result = Calculation.total_weight(new("3000"), false)
      # 3000 + 50 (packet) + 50 (samples) = 3100
      assert Decimal.equal?(result, new("3100"))
    end

    test "handles nil order_items_weight" do
      result = Calculation.total_weight(nil, false)
      # 0 + 50 (packet) + 50 (samples) = 100
      assert Decimal.equal?(result, new("100"))
    end

    test "handles nil order_items_weight with gift" do
      result = Calculation.total_weight(nil, true)
      # 0 + 50 (packet) + 50 (samples) + 100 (gift) = 200
      assert Decimal.equal?(result, new("200"))
    end
  end

  describe "can_count_post_cost?/2" do
    test "returns true when customer has valid pindex and total_weight is not nil" do
      customer = %{city: %{pindex: "123456"}}
      assert Calculation.can_count_post_cost?(customer, new("1000")) == true
    end

    test "returns false when customer has nil pindex" do
      customer = %{city: %{pindex: nil}}
      assert Calculation.can_count_post_cost?(customer, new("1000")) == false
    end

    test "returns false when customer has empty pindex" do
      customer = %{city: %{pindex: ""}}
      assert Calculation.can_count_post_cost?(customer, new("1000")) == false
    end

    test "returns false when customer has no city" do
      customer = %{}
      assert Calculation.can_count_post_cost?(customer, new("1000")) == false
    end

    test "returns false when total_weight is nil" do
      customer = %{city: %{pindex: "123456"}}
      assert Calculation.can_count_post_cost?(customer, nil) == false
    end

    test "returns false when customer is nil" do
      assert Calculation.can_count_post_cost?(nil, new("1000")) == false
    end
  end

  describe "get_post_cost/2" do
    test "returns post cost when customer has city" do
      customer = %{city: %{pindex: "190000"}}
      assert Calculation.get_post_cost(customer, new("1000")) == Decimal.new("448")
    end

    test "returns nil when customer has no city" do
      customer = %{}
      assert Calculation.get_post_cost(customer, new("1000")) == nil
    end

    test "returns nil when customer has nil pindex" do
      customer = %{city: %{pindex: nil}}
      assert Calculation.get_post_cost(customer, new("1000")) == nil
    end

    test "returns nil when customer has empty pindex" do
      customer = %{city: %{pindex: ""}}
      assert Calculation.get_post_cost(customer, new("1000")) == nil
    end
  end

  describe "calculate_all/1" do
    test "handles empty order items list" do
      result =
        Calculation.calculate_all(%{
          order_items: [],
          post_cost: new("500"),
          packet: 25
        })

      assert Decimal.equal?(result.order_items_price, new(0))
      assert Decimal.equal?(result.order_items_weight, new(0))
      assert result.need_gift? == false
      assert result.need_post_discount? == false
      assert Decimal.equal?(result.post_cost_with_packet, new("525"))
      assert Decimal.equal?(result.post_discount, new(0))

      assert Decimal.equal?(result.total_post_cost, new("525"))
    end

    test "does not apply post_discount when need_post_discount? is false" do
      # order_items_price = 999 < 1000 => скидка не применяется
      order_items = [
        %Ecto.Changeset{
          changes: %{
            action: :insert,
            amount: new("9"),
            price: new("111"),
            product: %{density: 0, width: 0}
          }
        }
      ]

      result =
        Calculation.calculate_all(%{
          order_items: order_items,
          post_cost: new("500"),
          packet: 25
        })

      assert result.need_post_discount? == false
      assert Decimal.equal?(result.post_discount, new(0))
      assert Decimal.equal?(result.total_post_cost, new("525"))
    end

    test "handles nil post_cost and packet" do
      result =
        Calculation.calculate_all(%{
          order_items: [],
          post_cost: nil,
          packet: nil
        })

      assert Decimal.equal?(result.post_cost_with_packet, new(0))
      assert Decimal.equal?(result.post_discount, new(0))
      assert Decimal.equal?(result.total_post_cost, new(0))
      assert Decimal.equal?(result.total_price, new(0))
    end

    test "handles nil order_items" do
      result =
        Calculation.calculate_all(%{
          order_items: nil,
          post_cost: new("500"),
          packet: 25
        })

      assert Decimal.equal?(result.order_items_price, new(0))
      assert Decimal.equal?(result.order_items_weight, new(0))
    end
  end

  describe "with_can_count_post_cost?/3" do
    test "updates can_count_post_cost? based on customer and total_weight" do
      calculation = %{can_count_post_cost?: nil}
      customer = %{city: %{pindex: "123456"}}

      result = Calculation.with_can_count_post_cost?(calculation, customer, new("1000"))
      assert result.can_count_post_cost? == true
    end

    test "sets can_count_post_cost? to false when customer has invalid pindex" do
      calculation = %{can_count_post_cost?: nil}
      customer = %{city: %{pindex: nil}}

      result = Calculation.with_can_count_post_cost?(calculation, customer, new("1000"))
      assert result.can_count_post_cost? == false
    end

    test "sets can_count_post_cost? to false when total_weight is nil" do
      calculation = %{can_count_post_cost?: nil}
      customer = %{city: %{pindex: "123456"}}

      result = Calculation.with_can_count_post_cost?(calculation, customer, nil)
      assert result.can_count_post_cost? == false
    end
  end

  describe "edge cases and decimal precision" do
    test "handles very small decimal values" do
      result = Calculation.order_item_price(new("0.01"), new("0.01"))
      # Result is rounded to 2 decimal places: 0.0001 -> 0.00
      assert Decimal.equal?(result, new("0.00"))
    end

    test "handles very large decimal values" do
      result = Calculation.order_item_price(new("1000000"), new("1000000"))
      assert Decimal.equal?(result, new("1000000000000"))
    end

    test "handles zero amount and price" do
      result = Calculation.order_item_price(new(0), new(0))
      assert Decimal.equal?(result, new(0))
    end

    test "calculates total_price with zero values" do
      result = Calculation.total_price(new(0), new(0))
      assert Decimal.equal?(result, new(0))
    end
  end
end
