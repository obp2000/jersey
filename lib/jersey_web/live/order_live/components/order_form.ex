defmodule JerseyWeb.OrderForm do
  use JerseyWeb, :html

  alias Phoenix.HTML.{Form, FormField}
  alias JerseyWeb.ProductField

  embed_templates "order_form/*"

  attr :field, FormField, required: true

  def delivery_type(assigns)

  def delivery_type_options do
    [
      {dgettext("delivery_types", "pochta"), :pochta},
      {dgettext("delivery_types", "delovie"), :delovie},
      {dgettext("delivery_types", "pek"), :pek},
      {dgettext("delivery_types", "kit"), :kit},
      {dgettext("delivery_types", "energy"), :energy},
      {dgettext("delivery_types", "zhde"), :zhde},
      {dgettext("delivery_types", "ratek"), :ratek},
      {dgettext("delivery_types", "baikal"), :baikal},
      {dgettext("delivery_types", "cdek"), :cdek}
    ]
  end

  def order_items_header(assigns)

  def if_no_order_items(assigns)

  attr :order_item, Form, required: true

  def order_item(assigns)

  def add_order_item_button(assigns)

  attr :value, :integer, required: true

  def delete_order_item_button(assigns)

  attr :order_items_price, :float, required: true
  attr :order_items_weight, :integer, required: true

  def order_items_totals(assigns)

  attr :field, FormField, required: true
  attr :weight, :integer

  def gift(assigns)

  attr :weight, :integer

  def samples(assigns)

  attr :field, FormField, required: true
  attr :options, :list, required: true
  attr :weight, :integer

  def packet(assigns)

  attr :field, FormField, required: true
  attr :can_count?, :boolean, required: true

  def post_cost(assigns)

  attr :post_cost_with_packet, :float, required: true
  attr :need_post_discount?, :boolean, required: true
  attr :post_discount, :float, required: true
  attr :total_post_cost, :float, required: true

  def post_cost_with_packet(assigns)

  attr :total_price, :float, required: true
  attr :total_weight, :integer, required: true

  def totals(assigns)
end
