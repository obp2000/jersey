defmodule JerseyWeb.CityField do
  use JerseyWeb, :live_component
  import LiveSelect
  alias Jersey.Customers.City
  alias Jersey.Customers

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options = Customers.search_cities(text) |> Enum.map(&city_option/1)
    send_update(LiveSelect.Component, id: live_select_id, options: options)
    {:noreply, socket}
  end

  def city_value_mapper(nil), do: nil
  def city_value_mapper(""), do: nil

  def city_value_mapper(id) when is_integer(id) or is_binary(id) do
    Customers.get_city!(id) |> city_option()
  end

  def city_value_mapper(_) do
    %City{} |> city_option()
  end

  def city_option(city) do
    %{
      label: Customers.full_city_name(city),
      value: city.id
    }
  end
end
