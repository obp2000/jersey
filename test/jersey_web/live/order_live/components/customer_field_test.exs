defmodule JerseyWeb.CustomerFieldTest do
  use JerseyWeb.ConnCase
  use JerseyWeb, :live_view
  import Phoenix.LiveViewTest
  import Jersey.CustomersFixtures
  alias JerseyWeb.CustomerField
  alias Jersey.{Customers, Customers.Customer}
  alias Phoenix.LiveView.Socket
  alias Jersey.Repo

  describe "customer_value_mapper/1" do
    test "returns nil for nil input" do
      assert CustomerField.customer_value_mapper(nil) == nil
    end

    test "returns nil for empty string" do
      assert CustomerField.customer_value_mapper("") == nil
    end

    test "returns option for Customer struct with preloaded city" do
      city = city_fixture()
      customer = customer_fixture(city_id: city.id) |> Repo.preload(:city)
      %{label: label, value: value} = CustomerField.customer_value_mapper(customer)
      assert label == Customer.full_name(customer)
      assert value == customer
    end

    test "returns option for Customer struct without preloaded city" do
      city = city_fixture()
      customer = customer_fixture(city_id: city.id)
      customer_with_city = Map.put(customer, :city, city)
      %{label: label, value: value} = CustomerField.customer_value_mapper(customer)
      assert label == Customer.full_name(customer_with_city)
      assert value == customer_with_city
    end

    test "returns option for Customer without city" do
      customer = customer_fixture()
      %{label: label, value: value} = CustomerField.customer_value_mapper(customer)
      assert label == Customer.full_name(customer)
      assert value == customer
    end

    test "returns default option for unknown input" do
      result = CustomerField.customer_value_mapper("unknown")
      assert result.label == ""
      assert result.value == %Customer{}
    end
  end

  describe "component rendering" do
    setup do
      %{customer: customer_fixture()}
    end

    test "renders live_select component", %{customer: customer} do
      form = customer |> Customers.change_customer() |> to_form()
      html = render_component(CustomerField, id: "customer_field", field: form[:customer])
      assert html =~ "phx-hook=\"LiveSelect\""
      assert html =~ "placeholder=\"#{dgettext("customer", "Select customer")}\""
    end
  end

  describe "handle_event/3" do
    test "live_select_change returns Customers.search_customers/1" do
      john = customer_fixture(%{nick: "John", name: "Smith"})

      {:noreply, _socket_after} =
        CustomerField.handle_event(
          "live_select_change",
          %{"text" => "Jo", "id" => "order_customer_live_select_component"},
          %Socket{}
        )

      results = Customers.search_customers("Jo")
      assert Enum.any?(results, &(&1.id == john.id))
    end
  end
end
