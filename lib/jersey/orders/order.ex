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

  def base_changeset(order, attrs) do
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
  end

  def changeset(order, attrs) do
    base_changeset(order, attrs)
    |> cast_assoc(:customer, with: &Customer.order_form_changeset/2)
    |> cast_assoc(:order_items,
      sort_param: :order_items_sort,
      drop_param: :order_items_drop
    )
    |> apply_calculations()
  end

  def save_changeset(order, attrs) do
    attrs = attrs |> Utils.maybe_decode_live_select_value("customer")

    base_changeset(order, attrs)
    |> cast_assoc(:order_items,
      sort_param: :order_items_sort,
      drop_param: :order_items_drop,
      with: &OrderItem.save_changeset/2
    )
    |> maybe_set_customer_id(attrs)
    |> cast(attrs, [:customer_id])
    |> validate_required([:customer_id])
    |> foreign_key_constraint(:customer_id, name: "orders_customer_id_fkey")
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

  defp maybe_set_customer_id(changeset, attrs) do
    customer_id = get_field(changeset, :customer_id)

    case Map.get(attrs, "customer") || Map.get(attrs, :customer) do
      %{id: id} when customer_id != id -> put_change(changeset, :customer_id, id)
      _ -> changeset
    end
  end

  def set_post_cost_if_possible(changeset) do
    total_weight = get_field(changeset, :total_weight)
    customer = get_assoc(changeset, :customer, :struct)
    can_count_post_cost? = get_field(changeset, :can_count_post_cost?)

    if can_count_post_cost? do
      post_cost = Calculation.get_post_cost(customer, total_weight)

      changeset |> put_change(:post_cost, post_cost) |> apply_calculations()
    else
      changeset
    end
  end
end
