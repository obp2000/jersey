defmodule Jersey.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Jersey.Customers.City
  alias Jersey.Orders.Order

  @derive {Jason.Encoder, only: [:id, :nick, :name, :address, :city_id, :city]}
  schema "customers" do
    field :nick, :string
    field :name, :string
    field :address, :string
    belongs_to :city, City
    has_many :orders, Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:id, :nick, :name, :address, :city_id])
    |> validate_required([:nick, :name])
    |> foreign_key_constraint(:city_id, name: "customers_city_id_fkey")
    |> foreign_key_constraint(:orders, name: "orders_customer_id_fkey")
  end

  def order_form_changeset(customer, attrs) do
    customer
    |> changeset(attrs)
    |> cast_assoc(:city)
  end

  def full_name(customer) do
    Enum.reject(
      [customer.nick, customer.name, City.full_name(customer.city), customer.address],
      fn x ->
        is_nil(x) or x == ""
      end
    )
    |> Enum.join(" ")
  end
end
