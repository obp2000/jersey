defmodule Jersey.Products.Product.CalculationTest do
  use Jersey.DataCase
  alias Jersey.Products.Product.Calculation

  defp d(val), do: Decimal.new(to_string(val))

  describe "price_rub_m/4" do
    test "returns 0 when any argument is nil" do
      assert Calculation.price_rub_m(nil, d(90), d(200), d(150)) |> Decimal.equal?(d(0))
      assert Calculation.price_rub_m(d(1.5), nil, d(200), d(150)) |> Decimal.equal?(d(0))
      assert Calculation.price_rub_m(d(1.5), d(90), nil, d(150)) |> Decimal.equal?(d(0))
      assert Calculation.price_rub_m(d(1.5), d(90), d(200), nil) |> Decimal.equal?(d(0))
    end

    test "calculates dollar_price * dollar_rate * density * width / 100_000 with integer div" do
      # 1.5 * 90 * 200 * 150 = 4_050_000
      # / 100_000 = 40.5 => integer division => 40
      assert Calculation.price_rub_m(d("1.5"), d("90"), d("200"), d("150"))
             |> Decimal.equal?(d(40))
    end
  end

  describe "prices/1" do
    test "returns 10 prices with coefficients from 1 to 2 step 0.1" do
      price_rub_m = d(100)

      prices = Calculation.prices(price_rub_m)

      assert length(prices) == 10
      assert prices |> Enum.map(&elem(&1, 0)) == [1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2]
    end

    test "rounds each price to integer" do
      price_rub_m = d(101)
      {1.2, price} = Calculation.prices(price_rub_m) |> Enum.find(fn {c, _} -> c == 1.2 end)
      rounded = price_rub_m |> Decimal.mult(d("1.2")) |> Decimal.round(0)
      assert Decimal.equal?(price, rounded)
    end

    test "for integer base and coeff=2 returns 2 * price_rub_m" do
      price_rub_m = d(123)

      {2, price} = Enum.find(Calculation.prices(price_rub_m), fn {c, _} -> c == 2 end)

      assert Decimal.equal?(price, d(246))
    end
  end

  describe "density_for_count/3" do
    test "returns 0 when any argument is nil" do
      assert Decimal.equal?(Calculation.density_for_count(nil, d(100), d(150)), d(0))
      assert Decimal.equal?(Calculation.density_for_count(d(500), nil, d(150)), d(0))
      assert Decimal.equal?(Calculation.density_for_count(d(500), d(100), nil), d(0))
    end

    test "returns 0 when length_for_count or width is 0" do
      assert Decimal.equal?(Calculation.density_for_count(d(500), d(0), d(150)), d(0))
      assert Decimal.equal?(Calculation.density_for_count(d(500), d(100), d(0)), d(0))
    end

    test "calculates weight_for_count / length_for_count / width * 100 and rounds to integer" do
      # (500/100)/150*100 = 3.333... => 3
      assert Calculation.density_for_count(d(500), d(100), d(150)) |> Decimal.equal?(d(3))
    end
  end

  describe "meters_in_roll/3" do
    test "returns 0 when any argument is nil" do
      assert Decimal.equal?(Calculation.meters_in_roll(nil, d(200), d(150)), d(0))
      assert Decimal.equal?(Calculation.meters_in_roll(d(1000), nil, d(150)), d(0))
      assert Decimal.equal?(Calculation.meters_in_roll(d(1000), d(200), nil), d(0))
    end

    test "returns 0 when density or width is 0" do
      assert Decimal.equal?(Calculation.meters_in_roll(d(1000), d(0), d(150)), d(0))
      assert Decimal.equal?(Calculation.meters_in_roll(d(1000), d(200), d(0)), d(0))
    end

    test "calculates weight / density / width * 100_000 and rounds to 2 decimals" do
      # 1000/200/150*100000 = 3333.3333... => 3333.33 (2 decimals)
      assert Calculation.meters_in_roll(d(1000), d(200), d(150)) |> Decimal.equal?(d("3333.33"))
    end
  end

  describe "calculate_all/1" do
    test "returns density_for_count, meters_in_roll and prices based on input map" do
      params = %{
        weight_for_count: d(500),
        length_for_count: d(100),
        width: d(150),
        weight: d(1000),
        density: d(200),
        dollar_price: d("1.5"),
        dollar_rate: d("90")
      }

      result = Calculation.calculate_all(params)

      assert Map.has_key?(result, :density_for_count)
      assert Map.has_key?(result, :meters_in_roll)
      assert Map.has_key?(result, :prices)

      assert Decimal.equal?(
               result.density_for_count,
               Calculation.density_for_count(d(500), d(100), d(150))
             )

      assert Decimal.equal?(
               result.meters_in_roll,
               Calculation.meters_in_roll(d(1000), d(200), d(150))
             )

      expected_prices =
        Calculation.price_rub_m(d("1.5"), d("90"), d(200), d(150))
        |> Calculation.prices()

      assert result.prices == expected_prices
    end
  end
end
