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
    field :set_price_from_product?, :boolean, virtual: true

    timestamps(type: :utc_datetime)
  end

  def base_changeset(order_item, attrs) do
    attrs =
      Jersey.Utils.maybe_decode_live_select_value(attrs, "product") |> maybe_set_product_id()

    order_item
    |> cast(attrs, [:order_id, :product_id, :amount, :price, :set_price_from_product?])
    |> validate_required([:amount, :price])
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:price, greater_than: 0)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:product_id)
    |> unique_constraint([:order_id, :product_id], name: :order_items_order_id_product_id_index)
  end

  def changeset(order_item, attrs) do
    attrs =
      Jersey.Utils.maybe_decode_live_select_value(attrs, "product")

    base_changeset(order_item, attrs)
    |> maybe_put_assoc_product(attrs)
    |> maybe_set_price_from_product()
    |> apply_calculations()
  end

  def save_changeset(order_item, attrs) do
    base_changeset(order_item, attrs)
  end

  defp maybe_set_product_id(%{"product" => %{id: id}} = attrs) do
    Map.put(attrs, "product_id", id)
  end

  defp maybe_set_product_id(%{"product" => ""} = attrs) do
    Map.put(attrs, "product_id", "")
  end

  defp maybe_set_product_id(attrs), do: attrs

  defp maybe_put_assoc_product(changeset, %{"product" => %{id: _id} = product}) do
    # IO.inspect(product)
    changeset |> put_assoc(:product, product)
  end

  defp maybe_put_assoc_product(changeset, _), do: changeset

  defp maybe_set_price_from_product(changeset) do
    set_price_from_product? = get_field(changeset, :set_price_from_product?)

    if set_price_from_product? do
      product = get_assoc(changeset, :product, :struct)
      put_change(changeset, :price, product.price)
    else
      changeset
    end
  end

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
end
