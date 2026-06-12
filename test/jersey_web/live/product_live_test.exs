defmodule JerseyWeb.ProductLiveTest do
  use JerseyWeb.ConnCase
  import Phoenix.LiveViewTest
  import Jersey.{ProductsFixtures, OrdersFixtures}

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

      assert {:ok, form_view, _} =
               index_live
               |> element("a.btn.btn-primary", "New Product")
               |> render_click()
               |> follow_redirect(conn, ~p"/products/new")

      assert render(form_view) =~ dgettext("product", "New Product")

      assert form_view |> validate_form(@invalid_attrs) =~
               dgettext("errors", "can&#39;t be blank")

      refute form_view |> validate_form(@create_attrs) =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, index_live, _html} =
               form_submit(form_view, @create_attrs) |> follow_redirect(conn, ~p"/products")

      html = render(index_live)
      assert html =~ dgettext("product", "Product created successfully")
      assert html =~ "some name"
    end

    test "updates product in listing", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert {:ok, form_view, _html} =
               index_live
               |> element("#entries-#{product.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/products/#{product}/edit")

      assert render(form_view) =~ dgettext("product", "Edit Product")

      assert form_view |> validate_form(@invalid_attrs) =~
               dgettext("errors", "can&#39;t be blank")

      assert {:ok, index_live, _html} =
               form_view |> form_submit(@update_attrs) |> follow_redirect(conn, ~p"/products")

      html = render(index_live)
      assert html =~ dgettext("product", "Product updated successfully")
      assert html =~ "some updated name"
    end

    test "deletes product in listing", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live
             |> element("#entries-#{product.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#entries-#{product.id}")
    end

    test "delete shows error when product has order items", %{conn: conn, product: product} do
      order_item = order_item_fixture(%{product_id: product.id})
      assert order_item.product_id == product.id

      {:ok, index_live, _html} = live(conn, ~p"/products")

      index_live
      |> element("#entries-#{product.id} a", "Delete")
      |> render_click()

      html = render(index_live)
      assert html =~ "Cannot delete product: it has associated order items"
      assert has_element?(index_live, "#entries-#{product.id}")
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

      assert {:ok, form_view, _} =
               show_live
               |> element("a", "Edit product")
               |> render_click()
               |> follow_redirect(conn, ~p"/products/#{product}/edit?return_to=show")

      assert render(form_view) =~ dgettext("product", "Edit Product")
      assert validate_form(form_view, @invalid_attrs) =~ dgettext("errors", "can&#39;t be blank")

      assert {:ok, show_live, _html} =
               form_submit(form_view, @update_attrs)
               |> follow_redirect(conn, ~p"/products/#{product}")

      html = render(show_live)
      assert html =~ dgettext("product", "Product updated successfully")
      assert html =~ "some updated name"
    end
  end

  defp validate_form(form_view, attrs) do
    form_view |> form("#product-form", product: attrs) |> render_change()
  end

  defp form_submit(form_view, attrs) do
    form_view |> form("#product-form", product: attrs) |> render_submit()
  end

  describe "Form with image upload" do
    setup [:create_product]

    test "creates product with image", %{conn: conn} do
      {:ok, form_view, _html} = live(conn, ~p"/products/new")
      assert render(form_view) =~ dgettext("product", "New Product")
      assert render_upload_image(form_view) =~ "100%"

      assert {:ok, index_live, _html} =
               form_submit(form_view, @create_attrs) |> follow_redirect(conn, ~p"/products")

      html = render(index_live)
      assert html =~ dgettext("product", "Product created successfully")
    end

    test "updates product with new image", %{conn: conn, product: product} do
      {:ok, form_view, _html} = live(conn, ~p"/products/#{product}/edit")
      assert render(form_view) =~ dgettext("product", "Edit Product")
      assert render_upload_image(form_view) =~ "100%"

      assert {:ok, index_live, _html} =
               form_submit(form_view, @update_attrs) |> follow_redirect(conn, ~p"/products")

      html = render(index_live)
      assert html =~ dgettext("product", "Product updated successfully")
      assert html =~ "some updated name"
    end

    test "handles image upload lifecycle", %{conn: conn} do
      {:ok, form_view, _html} = live(conn, ~p"/products/new")
      assert render_upload_image(form_view) =~ "100%"
      html = render(form_view)
      assert html =~ dgettext("product", "New Product")
    end

    test "shows upload error messages for too_many_files / not_accepted",
         %{conn: conn} do
      {:ok, form_view, _html} = live(conn, ~p"/products/new")

      too_many_entries = [image_entry(), image_entry()]
      entry_name = Enum.at(too_many_entries, 0).name

      {:error, _} =
        form_view
        |> file_input("#product-form", :image, too_many_entries)
        |> render_upload(entry_name)

      html = render(form_view)
      assert html =~ dgettext("product", "You have selected too many files")

      not_accepted_entry = %{image_entry() | name: "test.txt", type: "text/plain"}

      {:error, _} =
        form_view
        |> file_input("#product-form", :image, [not_accepted_entry])
        |> render_upload(not_accepted_entry.name)

      html = render(form_view)
      assert html =~ dgettext("product", "You have selected an unacceptable file type")
    end

    test "validates required fields", %{conn: conn} do
      {:ok, form_view, _html} = live(conn, ~p"/products/new")

      assert form_view |> validate_form(@invalid_attrs) =~
               dgettext("errors", "can&#39;t be blank")
    end

    test "save returns errors for new", %{conn: conn} do
      {:ok, form_view, _html} = live(conn, ~p"/products/new")

      assert form_view |> form_submit(@invalid_attrs) =~
               dgettext("errors", "can&#39;t be blank")
    end

    test "save returns errors for edit", %{conn: conn, product: product} do
      {:ok, form_view, _html} = live(conn, ~p"/products/#{product}/edit")

      assert form_view |> form_submit(@invalid_attrs) =~
               dgettext("errors", "can&#39;t be blank")
    end

    defp image_entry() do
      test_image_path = Path.join([File.cwd!(), "test", "support", "files", "test_image.png"])
      image_content = File.read!(test_image_path)

      %{
        last_modified: DateTime.to_unix(DateTime.utc_now(), :millisecond),
        name: "test_image.png",
        content: image_content,
        size: byte_size(image_content),
        type: "image/png"
      }
    end

    defp render_upload_image(form_view) do
      entry = image_entry()
      form_view |> file_input("#product-form", :image, [entry]) |> render_upload(entry.name)
    end
  end
end
