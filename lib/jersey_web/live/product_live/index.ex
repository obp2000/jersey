defmodule JerseyWeb.ProductLive.Index do
  use JerseyWeb, :live_view

  alias Jersey.Products
  import JerseyWeb.Pagination

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("product", "Listing Products"))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    %{
      entries: entries,
      total_pages: total_pages,
      page_number: page_number,
      total_entries: total_entries
    } = Products.paginate_products(params)

    {:noreply,
     socket
     |> assign(:page_number, page_number)
     |> assign(:total_entries, total_entries)
     |> assign(:total_pages, total_pages)
     |> stream(:entries, entries, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    # {:ok, _} = Products.delete_product(product)

    # {:noreply, stream_delete(socket, :products, product)}

    {:noreply,
     case Products.delete_product(product) do
       {:ok, _product} ->
         stream_delete(socket, :products, product)

       {:error, %Ecto.Changeset{errors: errors} = _changeset} ->
         put_flash(socket, :error, errors[:order_items] |> translate_error())
     end}
  end

  # def handle_event("delete", %{"id" => id}, socket) do
  #   product = Products.get_product!(id)

  #   case Products.delete_product(product) do
  #     {:ok, _product} ->
  #       {:noreply, stream_delete(socket, :products, product)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       if has_foreign_key_error?(changeset) do
  #         {:noreply,
  #          socket
  #          |> put_flash(:error, "Cannot delete product because it has existing order items")}
  #       else
  #         {:noreply, socket}
  #       end
  #   end
  # end

  # defp has_foreign_key_error?(changeset) do
  #   Enum.any?(changeset.errors, fn
  #     {:order_items, {"is still associated with existing order items", _}} -> true
  #     _ -> false
  #   end)
  # end
end
