defmodule Jersey.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset
  alias Jersey.Products.Product.Calculation
  alias Jersey.Orders.OrderItem
  alias Jersey.Utils

  @derive {Jason.Encoder, only: [:id, :name, :price, :width, :density]}
  schema "products" do
    field :name, :string
    field :price, :integer
    field :weight, :decimal
    field :width, :integer
    field :density, :integer
    field :dollar_price, :decimal
    field :dollar_rate, :decimal
    field :width_shop, :integer
    field :density_shop, :integer
    field :weight_for_count, :integer
    field :length_for_count, :decimal
    field :price_pre, :integer
    field :image, :string
    has_many :order_items, OrderItem

    field :density_for_count, :integer, virtual: true
    field :meters_in_roll, :decimal, virtual: true
    field :prices, :map, virtual: true

    timestamps(type: :utc_datetime)
  end

  def changeset(product, attrs \\ %{}) do
    product
    |> cast(attrs, [
      :id,
      :name,
      :price,
      :weight,
      :width,
      :density,
      :dollar_price,
      :dollar_rate,
      :width_shop,
      :density_shop,
      :weight_for_count,
      :length_for_count,
      :price_pre,
      :image
    ])
    |> validate_required([:name, :price])
    |> validate_number(:price, greater_than: 0)
    |> foreign_key_constraint(:order_items,
      name: "order_items_product_id_fkey",
      message: "Cannot delete product: it has associated order items"
    )
    |> apply_calculations()
  end

  @doc false
  def changeset(product, attrs, [path | _rest]) do
    changeset(product, attrs)
    |> put_change(:image, path)
  end

  def changeset(product, attrs, _) do
    changeset(product, attrs)
  end

  defp apply_calculations(changeset) do
    calculation =
      Calculation.calculate_all(
        Utils.get_fields(changeset, [
          :weight_for_count,
          :length_for_count,
          :width,
          :weight,
          :density,
          :dollar_price,
          :dollar_rate
        ])
      )

    changeset
    |> put_change(:density_for_count, calculation.density_for_count)
    |> put_change(:meters_in_roll, calculation.meters_in_roll)
    |> put_change(:prices, calculation.prices)
  end
end
