defmodule Jersey.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Jersey.Customers.Customer
  alias Jersey.Orders.{OrderItem, Order.Calculation}
  alias Jersey.Utils

  defdelegate gift_weight(), to: Calculation
  defdelegate samples_weight(), to: Calculation
  defdelegate packet_weight(), to: Calculation

  @packets [25, 27, 42, 72, 85]

  @delivery_types [
    pochta: 1,
    delovie: 2,
    pek: 3,
    kit: 4,
    energy: 5,
    zhde: 6,
    ratek: 7,
    baikal: 8,
    cdek: 9
  ]

  def packets, do: @packets

  schema "orders" do
    belongs_to :customer, Customer, on_replace: :nilify
    has_many :order_items, OrderItem, on_delete: :delete_all, on_replace: :delete
    field :delivery_type, Ecto.Enum, values: @delivery_types
    field :gift, :string
    field :packet, :integer
    field :post_cost, :integer
    field :address, :string

    field :order_items_price, :decimal, default: 0, virtual: true
    field :order_items_weight, :decimal, default: 0, virtual: true
    field :need_gift?, :boolean, default: false, virtual: true
    field :need_post_discount?, :boolean, default: false, virtual: true
    field :post_cost_with_packet, :decimal, virtual: true
    field :total_post_cost, :decimal, virtual: true
    field :post_discount, :decimal, default: 0, virtual: true
    field :total_price, :decimal, default: 0, virtual: true
    field :total_weight, :decimal, default: 0, virtual: true
    field :can_count_post_cost?, :boolean, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    attrs = attrs |> Utils.maybe_decode_live_select_value("customer")

    order
    |> cast(attrs, [
      :gift,
      :packet,
      :post_cost,
      :address,
      :delivery_type
    ])
    |> validate_inclusion(:packet, @packets)
    |> cast_assoc(:order_items, sort_param: :order_items_sort, drop_param: :order_items_drop)
    |> foreign_key_constraint(:customer_id, name: "orders_customer_id_fkey")
    |> cast_assoc(:customer, with: &Customer.order_form_changeset/2)
    |> apply_calculations()
    |> prepare_changes(&sync_customer_id/1)
  end

  defp apply_calculations(changeset) do
    order_items = get_assoc(changeset, :order_items)
    post_cost = get_field(changeset, :post_cost)
    packet = get_field(changeset, :packet)
    customer = get_assoc(changeset, :customer, :struct)

    calculation =
      Calculation.calculate_all(%{order_items: order_items, post_cost: post_cost, packet: packet})

    calculation =
      Calculation.with_can_count_post_cost?(calculation, customer, calculation.total_weight)

    changeset
    |> put_change(:order_items_price, calculation.order_items_price)
    |> put_change(:order_items_weight, calculation.order_items_weight)
    |> put_change(:need_gift?, calculation.need_gift?)
    |> put_change(:need_post_discount?, calculation.need_post_discount?)
    |> put_change(:post_cost_with_packet, calculation.post_cost_with_packet)
    |> put_change(:post_discount, calculation.post_discount)
    |> put_change(:total_post_cost, calculation.total_post_cost)
    |> put_change(:total_price, calculation.total_price)
    |> put_change(:total_weight, calculation.total_weight)
    |> put_change(:can_count_post_cost?, calculation.can_count_post_cost?)
  end

  defp sync_customer_id(changeset) do
    with {:ok, changed_customer} <- fetch_change(changeset, :customer),
         {:ok, changed_customer_id} <- fetch_change(changed_customer, :id) do
      changeset
      |> put_change(:customer_id, changed_customer_id)
      |> delete_change(:customer)
    else
      _ -> changeset
    end
  end

  def set_post_cost_if_possible(changeset) do
    total_weight = get_field(changeset, :total_weight)
    customer = get_assoc(changeset, :customer, :struct)

    calculation =
      Calculation.with_post_cost_if_possible(
        %{post_cost: get_field(changeset, :post_cost)},
        customer,
        total_weight
      )

    put_change(changeset, :post_cost, calculation.post_cost)
  end
end
