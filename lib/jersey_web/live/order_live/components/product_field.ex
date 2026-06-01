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

  defp product_value_mapper(nil), do: nil
  defp product_value_mapper(""), do: nil

  defp product_value_mapper(%Product{} = product) do
    product |> product_option()
  end

  defp product_value_mapper(_) do
    %Product{} |> product_option()
  end

  defp product_option(product) do
    %{
      label: product.name,
      value: product
    }
  end
end
