defmodule Jersey.Orders.Order.Calculation do
  @moduledoc """
  Pure calculation logic for Order fields.

  This module contains functions to compute derived fields based on order data.
  These functions are pure and side-effect free, designed to be called from
  changeset pipeline or directly from business logic.
  """

  import Ecto.Changeset
  alias Jersey.Clients.PostcalcClient

  @min_order_items_price_for_gift 2000
  @min_order_items_price_for_post_discount 1000
  @discount_rate Decimal.new("0.3")
  @packet_weight 50
  @samples_weight 50
  @gift_weight 100

  def gift_weight, do: @gift_weight
  def samples_weight, do: @samples_weight
  def packet_weight, do: @packet_weight

  def order_item_price(amount, price) when not is_nil(amount) and not is_nil(price) do
    amount |> Decimal.mult(price) |> Decimal.round(2)
  end

  def order_item_price(_, _), do: Decimal.new(0)

  def order_item_weight(amount, %{density: density, width: width})
      when not is_nil(amount) and not is_nil(density) and not is_nil(width) do
    amount
    |> Decimal.mult(density)
    |> Decimal.mult(width)
    |> Decimal.div(Decimal.new(100))
    |> Decimal.round(0)
  end

  def order_item_weight(_, _), do: Decimal.new(0)

  def calculate_order_item(%{
        amount: amount,
        price: price,
        product: product
      }) do
    order_item_price = order_item_price(amount, price)
    order_item_weight = order_item_weight(amount, product)

    %{
      order_item_price: order_item_price,
      order_item_weight: order_item_weight
    }
  end

  @doc """
  Calculates order_items_price from a list of order items.
  Returns 0 for empty or nil lists.
  """
  def order_items_price(order_items) when is_list(order_items) do
    order_items
    |> Enum.reject(&(&1.action == :delete))
    |> Enum.reduce(Decimal.new(0), fn order_item, acc ->
      amount = get_field(order_item, :amount)
      price = get_field(order_item, :price)
      Decimal.add(acc, order_item_price(amount, price))
    end)
  end

  def order_items_price(nil), do: Decimal.new(0)

  @doc """
  Calculates order_items_weight from a list of order items.
  Returns 0 for empty or nil lists.
  """
  def order_items_weight(order_items) when is_list(order_items) do
    order_items
    |> Enum.reject(&(&1.action == :delete))
    |> Enum.reduce(Decimal.new(0), fn order_item, acc ->
      amount = get_field(order_item, :amount)
      product = get_field(order_item, :product)
      Decimal.add(acc, order_item_weight(amount, product))
    end)
  end

  def order_items_weight(nil), do: Decimal.new(0)

  @doc """
  Determines if a gift is needed based on order items price.
  """
  def need_gift?(order_items_price) do
    Decimal.gt?(order_items_price, Decimal.new(@min_order_items_price_for_gift))
  end

  @doc """
  Determines if post discount is needed based on order items price.
  """
  def need_post_discount?(order_items_price) do
    order_items_price &&
      Decimal.gt?(order_items_price, Decimal.new(@min_order_items_price_for_post_discount))
  end

  @doc """
  Calculates post_cost_with_packet by adding packet weight to post_cost.
  """
  def post_cost_with_packet(post_cost, packet) do
    Decimal.add(post_cost || Decimal.new(0), Decimal.new(packet || 0))
  end

  @doc """
  Calculates post_discount from post_cost_with_packet.
  """
  def post_discount(post_cost_with_packet) do
    post_cost_with_packet |> Decimal.mult(@discount_rate) |> Decimal.round(0)
  end

  @doc """
  Calculates total_post_cost by subtracting post_discount from post_cost_with_packet.
  """
  def total_post_cost(post_cost_with_packet, post_discount) do
    if post_discount do
      Decimal.sub(post_cost_with_packet, post_discount)
    else
      post_cost_with_packet
    end
  end

  @doc """
  Calculates total_price by adding order_items_price and total_post_cost.
  """
  def total_price(order_items_price, total_post_cost) do
    order_items_price |> Decimal.add(total_post_cost)
  end

  @doc """
  Calculates total_weight from order_items_weight and need_gift? flag.
  """
  def total_weight(order_items_weight, need_gift?) do
    (order_items_weight || Decimal.new(0))
    |> Decimal.add(@packet_weight)
    |> Decimal.add(@samples_weight)
    |> then(fn weight -> if need_gift?, do: Decimal.add(weight, @gift_weight), else: weight end)
  end

  @doc """
  Determines if post_cost can be calculated based on customer and total_weight.
  Returns true if customer.city.pindex is a valid non-empty binary.
  """
  def can_count_post_cost?(customer, total_weight) do
    case customer do
      %{city: %{pindex: pindex}} when is_binary(pindex) and byte_size(pindex) > 0 ->
        not is_nil(total_weight)

      _ ->
        false
    end
  end

  @doc """
  Gets post_cost from PostcalcClient for given pindex and total_weight.
  Returns nil if calculation is not possible.
  """
  def get_post_cost(customer, total_weight) do
    case customer do
      %{city: %{pindex: pindex}} when is_binary(pindex) and byte_size(pindex) > 0 ->
        PostcalcClient.get_post_cost(pindex, total_weight) |> Decimal.round(0)

      _ ->
        nil
    end
  end

  @doc """
  Calculates all derived fields for an order based on input data.

  Accepts a map with the following keys:
  - `:order_items` - list of order items
  - `:post_cost` - base post cost
  - `:packet` - packet size/weight

  Returns a map with all calculated fields:
  - `:order_items_price`
  - `:order_items_weight`
  - `:need_gift?`
  - `:need_post_discount?`
  - `:post_cost_with_packet`
  - `:post_discount`
  - `:total_post_cost`
  - `:total_price`
  - `:total_weight`
  - `:can_count_post_cost?`
  """
  def calculate_all(%{
        order_items: order_items,
        post_cost: post_cost,
        packet: packet
      }) do
    order_items_price = order_items_price(order_items)
    order_items_weight = order_items_weight(order_items)
    need_gift? = need_gift?(order_items_price)
    need_post_discount? = need_post_discount?(order_items_price)
    post_cost_with_packet = post_cost_with_packet(post_cost, packet)
    post_discount = post_discount(post_cost_with_packet)
    total_post_cost = total_post_cost(post_cost_with_packet, post_discount)
    total_price = total_price(order_items_price, total_post_cost)
    total_weight = total_weight(order_items_weight, need_gift?)

    %{
      order_items_price: order_items_price,
      order_items_weight: order_items_weight,
      need_gift?: need_gift?,
      need_post_discount?: need_post_discount?,
      post_cost_with_packet: post_cost_with_packet,
      post_discount: post_discount,
      total_post_cost: total_post_cost,
      total_price: total_price,
      total_weight: total_weight,
      # customer is needed for this
      can_count_post_cost?: nil,
      post_cost: post_cost
    }
  end

  @doc """
  Updates can_count_post_cost? field based on customer and total_weight.
  """
  def with_can_count_post_cost?(calculation, customer, total_weight) do
    %{calculation | can_count_post_cost?: can_count_post_cost?(customer, total_weight)}
  end

  @doc """
  Calculates post_cost for an order if possible, returns updated calculation map.
  Returns original calculation if post_cost cannot be calculated.
  """
  def with_post_cost_if_possible(calculation, customer, total_weight) do
    if can_count_post_cost?(customer, total_weight) do
      post_cost = get_post_cost(customer, total_weight)
      %{calculation | post_cost: post_cost}
    else
      calculation
    end
  end
end
