defmodule JerseyWeb.OrderLive.FormTest do
  use JerseyWeb.ConnCase
  import Phoenix.LiveViewTest
  import Jersey.{CustomersFixtures, OrdersFixtures}
  # import Jersey.ProductsFixtures

  @invalid_attrs %{address: nil, delivery_type: ""}
  @valid_attrs %{
    address: nil,
    delivery_type: "cdek",
    order_items_drop: [""],
    packet: "",
    post_cost: ""
  }

  defp validate_form(form_view, attrs) do
    form_view
    |> form("#order-form", order: attrs)
    |> render_change()
  end

  describe "OrderLive.Form (new)" do
    test "renders form", %{conn: conn} do
      {:ok, form_view, _html} = live(conn, ~p"/orders/new")
      html = render(form_view)
      assert html =~ dgettext("order", "New Order")
      assert has_element?(form_view, "#order-form")
      assert has_element?(form_view, "input[name='order[address]']")
      assert has_element?(form_view, "button", dgettext("order", "Save Order"))
    end

    test "validate returns errors for required fields", %{conn: conn} do
      {:ok, form_view, _html} = live(conn, ~p"/orders/new")
      html = validate_form(form_view, @invalid_attrs)
      assert html =~ dgettext("errors", "invalid")
    end

    test "save returns errors for new", %{conn: conn} do
      {:ok, form_view, _html} = live(conn, ~p"/orders/new")

      html =
        form_view
        |> form("#order-form", order: @invalid_attrs)
        |> render_submit()

      assert html =~ "Something went wrong"
    end

    test "saves new order", %{conn: conn} do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})
      {:ok, form_view, _html} = live(conn, ~p"/orders/new")

      assert {:ok, index_live, _html} =
               form_view
               |> form("#order-form", order: @valid_attrs)
               |> render_submit(%{order: %{"customer" => Jason.encode!(customer)}})
               |> follow_redirect(conn, ~p"/orders")

      html = render(index_live)
      assert html =~ dgettext("order", "Order created successfully")
      assert html =~ customer.nick
    end
  end

  describe "OrderLive.Form (edit)" do
    setup do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})
      order = order_fixture(%{customer_id: customer.id})
      %{order: order, customer: customer}
    end

    test "renders edit page", %{conn: conn, order: order} do
      {:ok, form_view, _html} = live(conn, ~p"/orders/#{order}/edit")
      html = render(form_view)
      assert html =~ dgettext("order", "Edit Order N %{id}", id: order.id)
      assert has_element?(form_view, "#order-form")
    end

    test "updates order", %{conn: conn, order: order} do
      {:ok, form_view, _html} = live(conn, ~p"/orders/#{order}/edit")

      assert {:ok, index_live, _html} =
               form_view
               |> form("#order-form", order: @valid_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/orders")

      html = render(index_live)
      assert html =~ dgettext("order", "Order updated successfully")
    end
  end

  describe "OrderLive.Form (event handlers)" do
    test "phx-change=validate updates the form state", %{conn: conn} do
      {:ok, form_view, _html} = live(conn, ~p"/orders/new")
      html = validate_form(form_view, %{address: "test", delivery_type: ""})
      assert html =~ dgettext("errors", "invalid")
    end
  end

  describe "OrderLive.Form (navigation return_to=show)" do
    test "edit: cancel navigates to show page when return_to=show", %{conn: conn} do
      city = city_fixture()
      customer = customer_fixture(%{city_id: city.id})
      order = order_fixture(%{customer_id: customer.id})
      {:ok, form_view, _html} = live(conn, ~p"/orders/#{order}/edit?return_to=show")
      assert has_element?(form_view, "a", "Cancel")
      to = "/orders/#{order.id}"

      assert {:error, {:live_redirect, %{kind: :push, to: ^to}}} =
               form_view |> element("footer a", "Cancel") |> render_click()
    end
  end
end
