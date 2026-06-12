defmodule JerseyWeb.CityFieldTest do
  use JerseyWeb.ConnCase
  use JerseyWeb, :live_view
  import Phoenix.LiveViewTest
  import Jersey.CustomersFixtures
  alias JerseyWeb.CityField
  alias Jersey.Customers
  alias Phoenix.LiveView.Socket

  describe "city_value_mapper/1" do
    test "returns nil for nil input" do
      assert CityField.city_value_mapper(nil) == nil
    end

    test "returns nil for empty string" do
      assert CityField.city_value_mapper("") == nil
    end

    test "returns option for integer input" do
      city = city_fixture()

      %{label: label, value: value} = CityField.city_value_mapper(city.id)
      assert label == Customers.full_city_name(city)
      assert value == city.id
    end

    test "returns option for binary input" do
      city = city_fixture()

      %{label: label, value: value} = CityField.city_value_mapper(Integer.to_string(city.id))
      assert label == Customers.full_city_name(city)
      assert value == city.id
    end

    test "returns default option for unknown input" do
      result = CityField.city_value_mapper(%{})
      assert result.label == ""
      assert result.value == nil
    end
  end

  describe "component rendering" do
    setup do
      %{city: city_fixture()}
    end

    test "renders live_select component", %{city: city} do
      customer = customer_fixture(%{city_id: city.id})
      form = Customers.change_customer(customer) |> to_form()

      html = render_component(CityField, id: "city_field", field: form[:city_id])
      assert html =~ "phx-hook=\"LiveSelect\""
      assert html =~ "placeholder=\"#{dgettext("city", "Select city")}\""
    end
  end

  describe "handle_event/3" do
    test "live_select_change returns Customers.search_cities/1" do
      city2 = city_fixture(%{pindex: "190000"})

      {:noreply, _socket_after} =
        CityField.handle_event(
          "live_select_change",
          %{"text" => "190", "id" => "customer_city_live_select_component"},
          %Socket{}
        )

      results = Customers.search_cities("190")
      assert Enum.any?(results, &(&1.id == city2.id))
    end
  end
end
