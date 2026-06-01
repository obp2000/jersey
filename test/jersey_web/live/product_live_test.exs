defmodule JerseyWeb.ProductLiveTest do
  use JerseyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jersey.ProductsFixtures

  @create_attrs %{name: "some name", price: 42}
  @update_attrs %{name: "some updated name", price: 43}
  @invalid_attrs %{name: nil, price: nil}

  defp create_product(_), do: %{product: product_fixture()}

  describe "Index" do
    setup [:create_product]

    test "lists all products", %{conn: conn, product: product} do
      {:ok, _index_live, html} = live(conn, ~p"/products")

      assert html =~ dgettext("product", "Listing Products")
      assert html =~ product.name
    end

    test "saves new product", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert {:ok, form_live, _} =
               index_live
               |> element("a.btn.btn-primary", "New Product")
               |> render_click()
               |> follow_redirect(conn, ~p"/products/new")

      assert render(form_live) =~ dgettext("product", "New Product")

      assert form_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, index_live, _html} =
               form_live
               |> form("#product-form", product: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/products")

      html = render(index_live)
      assert html =~ dgettext("product", "Product created successfully")
      assert html =~ "some name"
    end

    test "updates product in listing", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#entries-#{product.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/products/#{product}/edit")

      assert render(form_live) =~ dgettext("product", "Edit Product")

      assert form_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, index_live, _html} =
               form_live
               |> form("#product-form", product: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/products")

      html = render(index_live)
      assert html =~ dgettext("product", "Product updated successfully")
      assert html =~ "some updated name"
    end

    # @tag :skip
    test "deletes product in listing", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")
      assert index_live |> element("#entries-#{product.id} a", "Delete")
    end
  end

  describe "Show" do
    setup [:create_product]

    test "displays product", %{conn: conn, product: product} do
      {:ok, _show_live, html} = live(conn, ~p"/products/#{product}")

      assert html =~ dgettext("product", "Product")
      assert html =~ product.name
    end

    test "updates product and returns to show", %{conn: conn, product: product} do
      {:ok, show_live, _html} = live(conn, ~p"/products/#{product}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit product")
               |> render_click()
               |> follow_redirect(conn, ~p"/products/#{product}/edit?return_to=show")

      assert render(form_live) =~ dgettext("product", "Edit Product")

      assert form_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, show_live, _html} =
               form_live
               |> form("#product-form", product: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/products/#{product}")

      html = render(show_live)
      assert html =~ dgettext("product", "Product updated successfully")
      assert html =~ "some updated name"
    end
  end
end
