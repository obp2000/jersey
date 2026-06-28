defmodule JerseyWeb.OrderLive.Form do
  use JerseyWeb, :live_view

  alias Jersey.Orders
  alias Jersey.Orders.Order
  alias JerseyWeb.CustomerField
  alias Jersey.Repo

  import JerseyWeb.OrderForm

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    order = Orders.get_order!(id)

    socket
    |> assign(:page_title, dgettext("order", "Edit Order N %{id}", id: id))
    |> assign(:order, order)
    |> assign(:form, to_form(Orders.change_order(order)))
  end

  defp apply_action(socket, :new, _params) do
    order = %Order{} |> Repo.preload(customer: :city)

    socket
    |> assign(:page_title, dgettext("order", "New Order"))
    |> assign(:order, order)
    |> assign(:form, to_form(Orders.change_order(order)))
  end

  @impl true
  def handle_event("validate", %{"order" => order_params} = params, socket) do
    order_params = handle_target(order_params, params["_target"])
    changeset = Orders.change_order(socket.assigns.order, order_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"order" => order_params}, socket) do
    save_order(socket, socket.assigns.live_action, order_params)
  end

  def handle_event("set_post_cost", _params, socket) do
    changeset = Orders.change_order(socket.assigns.order) |> Orders.set_post_cost_if_possible()
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  defp save_order(socket, :edit, order_params) do
    case Orders.update_order(socket.assigns.order, order_params) do
      {:ok, order} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("order", "Order updated successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, order))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_order(socket, :new, order_params) do
    case Orders.create_order(order_params) do
      {:ok, order} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("order", "Order created successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, order))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _order), do: ~p"/orders"
  defp return_path("show", order), do: ~p"/orders/#{order}"

  defp handle_target(order_params, ["order", "order_items", order_item_index, "product"]) do
    put_in(order_params, ["order_items", order_item_index, "set_price_from_product?"], true)
  end

  defp handle_target(order_params, _), do: order_params
end
