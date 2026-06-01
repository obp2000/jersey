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

  def changeset(order_item, attrs) do
    attrs = Jersey.Utils.maybe_decode_live_select_value(attrs, "product")

    order_item
    |> cast(attrs, [:amount, :price])
    |> validate_required([:amount, :price])
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:price, greater_than: 0)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:product_id)
    |> unique_constraint([:order_id, :product_id], name: :order_items_order_id_product_id_index)
    # Cast product association to calculate totals (density/width) when product comes from Live select
    |> cast_assoc(:product)
    |> maybe_set_price_from_product()
    |> apply_calculations()
    |> prepare_changes(&sync_product_id/1)
  end

  def maybe_set_price_from_product(changeset) do
    with {:ok, changed_product} <- fetch_change(changeset, :product),
         {:ok, changed_product_price} when not is_nil(changed_product_price) <-
           fetch_change(changed_product, :price) do
      changeset
      |> put_change(:price, changed_product_price)
    else
      _ -> changeset
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

  defp sync_product_id(changeset) do
    with {:ok, product} <- fetch_change(changeset, :product),
         {:ok, product_id} <- fetch_change(product, :id) do
      changeset |> put_change(:product_id, product_id) |> delete_change(:product)
    else
      _ -> changeset
    end
  end
end
