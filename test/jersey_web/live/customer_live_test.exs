defmodule JerseyWeb.CustomerLiveTest do
  use JerseyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jersey.CustomersFixtures

  @create_attrs %{name: "some name", nick: "some nick"}
  @update_attrs %{name: "some updated name", nick: "some updated nick"}
  @invalid_attrs %{name: nil, nick: nil}

  defp create_customer(_) do
    customer = customer_fixture()

    %{customer: customer}
  end

  describe "Index" do
    setup [:create_customer]

    test "lists all customers", %{conn: conn, customer: customer} do
      {:ok, _index_live, html} = live(conn, ~p"/customers")

      assert html =~ dgettext("customer", "Listing Customers")
      assert html =~ customer.nick
    end

    test "saves new customer", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/customers")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", dgettext("customer", "New Customer"))
               |> render_click()
               |> follow_redirect(conn, ~p"/customers/new")

      assert render(form_live) =~ dgettext("customer", "New Customer")

      assert form_live
             |> form("#customer-form", customer: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, index_live, _html} =
               form_live
               |> form("#customer-form", customer: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/customers")

      html = render(index_live)
      assert html =~ dgettext("customer", "Customer created successfully")
      assert html =~ "some nick"
    end

    test "updates customer in listing", %{conn: conn, customer: customer} do
      {:ok, index_live, _html} = live(conn, ~p"/customers")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#customers-#{customer.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/customers/#{customer}/edit")

      assert render(form_live) =~ dgettext("customer", "Edit Customer")

      assert form_live
             |> form("#customer-form", customer: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, index_live, _html} =
               form_live
               |> form("#customer-form", customer: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/customers")

      html = render(index_live)
      assert html =~ dgettext("customer", "Customer updated successfully")
      assert html =~ "some updated nick"
    end

    test "deletes customer in listing", %{conn: conn, customer: customer} do
      {:ok, index_live, _html} = live(conn, ~p"/customers")

      assert index_live |> element("#customers-#{customer.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#customers-#{customer.id}")
    end
  end

  describe "Show" do
    setup [:create_customer]

    test "displays customer", %{conn: conn, customer: customer} do
      {:ok, _show_live, html} = live(conn, ~p"/customers/#{customer}")

      assert html =~ dgettext("customer", "Show Customer")
      assert html =~ customer.nick
    end

    test "updates customer and returns to show", %{conn: conn, customer: customer} do
      {:ok, show_live, _html} = live(conn, ~p"/customers/#{customer}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/customers/#{customer}/edit?return_to=show")

      assert render(form_live) =~ dgettext("customer", "Edit Customer")

      assert form_live
             |> form("#customer-form", customer: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, show_live, _html} =
               form_live
               |> form("#customer-form", customer: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/customers/#{customer}")

      html = render(show_live)
      assert html =~ dgettext("customer", "Customer updated successfully")
      assert html =~ "some updated nick"
    end
  end
end
