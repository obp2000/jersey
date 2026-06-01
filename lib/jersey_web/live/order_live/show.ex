defmodule JerseyWeb.OrderLive.Show do
  use JerseyWeb, :live_view

  alias Jersey.Orders
  alias Jersey.Customers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("order", "Show Order"))
     |> assign(:order, Orders.get_order!(id))}
  end
end
