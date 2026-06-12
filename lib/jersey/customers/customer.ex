defmodule Jersey.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Jersey.Customers.City
  alias Jersey.Orders.Order

  @derive {Jason.Encoder, only: [:id, :nick, :name, :address, :city_id]}
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

  def full_name(%{} = customer) do
    city_full_name = Map.get(customer, :city) |> City.full_name()

    Enum.reject(
      [customer.nick, customer.name, city_full_name, customer.address],
      &(is_nil(&1) or &1 == "")
    )
    |> Enum.join(" ")
  end

  def full_name(_), do: ""
end
