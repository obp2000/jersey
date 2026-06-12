defmodule Jersey.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Jersey.Orders.{Order, Order.Calculation}
  alias Jersey.Products.Product

  schema "order_items" do
    field :amount, :decimal
    field :price, :decimal
    belongs_to :order, Order
    belongs_to :product, Product, on_replace: :nilify

    field :order_item_price, :decimal, virtual: true
    field :order_item_weight, :decimal, virtual: true

    timestamps(type: :utc_datetime)
  end

  def base_changeset(order_item, attrs) do
    attrs = Jersey.Utils.maybe_decode_live_select_value(attrs, "product")

    order_item
    |> cast(attrs, [:amount, :price, :order_id])
    |> validate_required([:amount, :price])
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:price, greater_than: 0)
  end

  def changeset(order_item, attrs) do
    base_changeset(order_item, attrs)
    # Cast product association to calculate totals (density/width) when product comes from Live select
    |> cast_assoc(:product)
    |> maybe_set_price_from_product()
    |> apply_calculations()
  end

  def save_changeset(order_item, attrs) do
    attrs = Jersey.Utils.maybe_decode_live_select_value(attrs, "product")

    base_changeset(order_item, attrs)
    |> foreign_key_constraint(:order_id)
    |> maybe_set_product_id(attrs)
    |> cast(attrs, [:product_id])
    |> foreign_key_constraint(:product_id)
    |> unique_constraint([:order_id, :product_id], name: :order_items_order_id_product_id_index)
  end

  defp maybe_set_price_from_product(
         %{changes: %{product: %{changes: %{price: price}}}} = changeset
       )
       when not is_nil(price) do
    put_change(changeset, :price, price)
  end

  defp maybe_set_price_from_product(changeset), do: changeset

  defp apply_calculations(changeset) do
    amount = get_field(changeset, :amount)
    price = get_field(changeset, :price)
    product = get_assoc(changeset, :product, :struct)

    calculation =
      Calculation.calculate_order_item(%{amount: amount, price: price, product: product})

    changeset
    |> put_change(:order_item_price, calculation.order_item_price)
    |> put_change(:order_item_weight, calculation.order_item_weight)
  end

  defp maybe_set_product_id(changeset, attrs) do
    product_id = get_field(changeset, :product_id)

    case attrs["product"] do
      %{id: id} when product_id != id -> put_change(changeset, :product_id, id)
      _ -> changeset
    end
  end
end
