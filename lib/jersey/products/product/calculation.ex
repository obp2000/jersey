defmodule Jersey.Products.Product.Calculation do
  @price_coeffs [1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2]

  def price_rub_m(dollar_price, dollar_rate, density, width) do
    if is_nil(dollar_price) or is_nil(dollar_rate) or is_nil(density) or is_nil(width) do
      Decimal.new(0)
    else
      dollar_price
      |> Decimal.mult(dollar_rate)
      |> Decimal.mult(density)
      |> Decimal.mult(width)
      |> Decimal.div_int(100_000)
    end
  end

  def prices(price_rub_m) do
    Enum.map(
      @price_coeffs,
      &{&1, Decimal.mult(price_rub_m, Decimal.new(to_string(&1))) |> Decimal.round(0)}
    )
  end

  def density_for_count(weight_for_count, length_for_count, width) do
    if is_nil(weight_for_count) or is_nil(length_for_count) or is_nil(width) or
         Decimal.equal?(length_for_count, 0) or Decimal.equal?(width, 0) do
      Decimal.new(0)
    else
      weight_for_count
      |> Decimal.div(length_for_count)
      |> Decimal.div(width)
      |> Decimal.mult(100)
      |> Decimal.round(0)
    end
  end

  def meters_in_roll(weight, density, width) do
    if is_nil(weight) or is_nil(density) or is_nil(width) or
         Decimal.equal?(density, 0) or Decimal.equal?(width, 0) do
      Decimal.new(0)
    else
      weight
      |> Decimal.div(density)
      |> Decimal.div(width)
      |> Decimal.mult(100_000)
      |> Decimal.round(2)
    end
  end

  def calculate_all(%{
        weight_for_count: weight_for_count,
        length_for_count: length_for_count,
        width: width,
        weight: weight,
        density: density,
        dollar_price: dollar_price,
        dollar_rate: dollar_rate
      }) do
    density_for_count = density_for_count(weight_for_count, length_for_count, width)
    meters_in_roll = meters_in_roll(weight, density, width)
    prices = price_rub_m(dollar_price, dollar_rate, density, width) |> prices()

    %{
      density_for_count: density_for_count,
      meters_in_roll: meters_in_roll,
      prices: prices
    }
  end
end
