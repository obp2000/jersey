defmodule JerseyWeb.OrderLive.Index do
  use JerseyWeb, :live_view
  alias Jersey.{Orders, Customers}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("order", "Listing Orders"))
     |> stream(:orders, Orders.list_orders())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    order = Orders.get_order!(id)
    {:ok, _} = Orders.delete_order(order)

    {:noreply, stream_delete(socket, :orders, order)}
  end
end
