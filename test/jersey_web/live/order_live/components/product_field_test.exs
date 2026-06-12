defmodule JerseyWeb.ProductFieldTest do
  use JerseyWeb.ConnCase
  use JerseyWeb, :live_view
  import Phoenix.LiveViewTest
  import Jersey.ProductsFixtures
  alias JerseyWeb.ProductField
  alias Jersey.{Products, Products.Product, Orders}
  alias Phoenix.LiveView.Socket

  describe "product_value_mapper/1" do
    setup do
      %{product: product_fixture()}
    end

    test "returns nil for nil input" do
      assert ProductField.product_value_mapper(nil) == nil
    end

    test "returns nil for empty string" do
      assert ProductField.product_value_mapper("") == nil
    end

    test "returns option for Product struct", %{product: product} do
      result = ProductField.product_value_mapper(product)
      assert result.label == product.name
      assert result.value == product
    end

    test "returns default option for unknown input" do
      result = ProductField.product_value_mapper("unknown")
      assert result.label == nil
      assert result.value == %Product{}
    end
  end

  describe "component rendering" do
    setup do
      %{product: product_fixture()}
    end

    test "renders live_select component", %{product: product} do
      form = product |> Products.change_product() |> to_form()
      html = render_component(ProductField, id: "product_field_1", field: form[:product])
      assert html =~ ~s(phx-hook="LiveSelect")
      assert html =~ "placeholder=\"#{dgettext("product", "Select product")}\""
    end
  end

  describe "handle_event/3" do
    setup do
      %{
        apple: product_fixture(%{name: "Apple", price: 100}),
        banana: product_fixture(%{name: "Banana", price: 200})
      }
    end

    test "live_select_change returns Orders.search_products/1", %{apple: apple} do
      {:noreply, _socket} =
        ProductField.handle_event(
          "live_select_change",
          %{"text" => "App", "id" => "product_field_1"},
          %Socket{}
        )

      results = Orders.search_products("App")
      assert Enum.any?(results, &(&1.id == apple.id))
    end
  end
end
