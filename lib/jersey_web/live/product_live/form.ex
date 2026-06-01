defmodule JerseyWeb.ProductLive.Form do
  use JerseyWeb, :live_view
  import JerseyWeb.ProductForm

  alias Jersey.Products
  alias Jersey.Products.Product

  @impl true
  def mount(params, _session, %{assigns: %{live_action: live_action}} = socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(live_action, params)
     |> assign(:uploaded_files, [])
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    product = Products.get_product!(id)
    changeset = Products.change_product(product)

    socket
    |> assign(:page_title, dgettext("product", "Edit Product"))
    |> assign(:product, product)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :new, _params) do
    product = %Product{}
    changeset = Products.change_product(product)

    socket
    |> assign(:page_title, dgettext("product", "New Product"))
    |> assign(:product, product)
    |> assign(:form, to_form(changeset))
  end

  @impl true
  def handle_event(
        "validate",
        %{"product" => product_params},
        %{assigns: %{product: product}} = socket
      ) do
    changeset = Products.change_product(product, product_params)

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event(
        "save",
        %{"product" => product_params},
        %{assigns: %{live_action: live_action}} = socket
      ) do
    uploaded_files = consume_uploaded_entries(socket, :image, &save_uploaded_file/2)

    socket
    |> update(:uploaded_files, &(&1 ++ uploaded_files))
    |> save_product(live_action, product_params)
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  defp save_product(
         %{assigns: %{product: product, uploaded_files: uploaded_files, return_to: return_to}} =
           socket,
         :edit,
         product_params
       ) do
    case Products.update_product(product, product_params, uploaded_files) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("product", "Product updated successfully"))
         |> push_navigate(to: return_path(return_to, product))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_product(
         %{assigns: %{uploaded_files: uploaded_files, return_to: return_to}} = socket,
         :new,
         product_params
       ) do
    case Products.create_product(product_params, uploaded_files) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("product", "Product created successfully"))
         |> push_navigate(to: return_path(return_to, product))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _product), do: ~p"/products"
  defp return_path("show", product), do: ~p"/products/#{product}"

  # def params_with_image(socket, params) do
  #   case consume_uploaded_entries(socket, :image, &save_uploaded_file/2) do
  #     [] -> params
  #     [path | _rest] -> Map.put(params, "image", path)
  #   end
  # end

  defp save_uploaded_file(%{path: path}, _entry) do
    dest = Path.join("priv/static/uploads", Path.basename(path))
    File.cp!(path, dest)
    {:ok, ~p"/uploads/#{Path.basename(dest)}"}
  end
end
