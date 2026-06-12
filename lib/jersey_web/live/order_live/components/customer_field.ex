defmodule JerseyWeb.CustomerField do
  use JerseyWeb, :live_component
  import LiveSelect
  alias Jersey.Orders
  alias Jersey.Customers.{Customer, City}
  alias Jersey.Customers

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options = Orders.search_customers(text) |> Enum.map(&customer_option/1)
    send_update(LiveSelect.Component, id: live_select_id, options: options)
    {:noreply, socket}
  end

  def customer_value_mapper(nil), do: nil
  def customer_value_mapper(""), do: nil

  def customer_value_mapper(%{city: %City{}} = customer) do
    customer |> customer_option()
  end

  def customer_value_mapper(%{city_id: city_id} = customer) when not is_nil(city_id) do
    city = Customers.get_city!(city_id)
    customer|> Map.put(:city, city) |> customer_option()
  end

  def customer_value_mapper(%{id: _id} = customer) do
    customer |> customer_option()
  end

  def customer_value_mapper(_) do
    %Customer{} |> customer_option()
  end

  def customer_option(customer) do
    %{
      label: Customer.full_name(customer),
      value: customer
    }
  end
end
