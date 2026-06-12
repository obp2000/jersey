defmodule Jersey.Customers.City do
  use Ecto.Schema
  import Ecto.Changeset
  alias Jersey.Customers.Customer

  @derive {Jason.Encoder, only: [:id, :pindex, :name]}
  schema "cities" do
    field :pindex, :string
    field :name, :string
    has_many :customers, Customer

    timestamps(type: :utc_datetime)
  end

  def changeset(city, attrs \\ %{}) do
    city
    |> cast(attrs, [:pindex, :name])
    |> validate_required([:pindex, :name])
    |> foreign_key_constraint(:customers,
      name: "customers_city_id_fkey",
      message: "Cannot delete city: it has associated customers"
    )
  end

  def full_name(%{id: _id} = city) do
    Enum.reject([city.pindex, city.name], fn x -> is_nil(x) or x == "" end) |> Enum.join(" ")
  end

  def full_name(_), do: ""
end
