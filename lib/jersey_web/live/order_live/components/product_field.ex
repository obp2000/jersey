defmodule JerseyWeb.ProductField do
  use JerseyWeb, :live_component
  import LiveSelect
  alias Jersey.Orders
  alias Jersey.Products.Product

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options = Orders.search_products(text) |> Enum.map(&product_option/1)
    send_update(LiveSelect.Component, id: live_select_id, options: options)
    {:noreply, socket}
  end
  def product_value_mapper(nil), do: nil
  def product_value_mapper(""), do: nil

  def product_value_mapper(%{id: _id} = product) do
    product |> product_option()
  end

  def product_value_mapper(_) do
    %Product{} |> product_option()
  end
  def product_option(product) do
    %{
      label: product.name,
      value: product
    }
  end
end
