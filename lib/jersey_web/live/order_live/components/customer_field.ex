defmodule JerseyWeb.CustomerField do
  use JerseyWeb, :live_component
  import LiveSelect
  alias Jersey.Orders
  alias Jersey.Customers.Customer
  # alias Jersey.Customers
  # alias Jersey.Repo

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options = Orders.search_customers(text) |> Enum.map(&customer_option/1)
    send_update(LiveSelect.Component, id: live_select_id, options: options)
    {:noreply, socket}
  end

  defp customer_value_mapper(nil), do: nil
  defp customer_value_mapper(""), do: nil

  defp customer_value_mapper(id) when is_integer(id) or is_binary(id) do
    Orders.get_customer!(id) |> customer_option()
  end

  defp customer_value_mapper(%{city: _city} = customer) do
    customer |> customer_option()
  end

  defp customer_option(customer) do
    %{
      label: Customer.full_name(customer),
      value: customer
      # value: %{
      #   id: customer.id,
      #   nick: customer.nick,
      #   name: customer.name,
      #   city_id: customer.city_id,
      #   # city: customer.city,
      #   city: %{
      #     id: customer.city.id,
      #     pindex: customer.city.pindex,
      #     name: customer.city.name
      #   },
      #   address: customer.address
      # }
    }
  end
end
