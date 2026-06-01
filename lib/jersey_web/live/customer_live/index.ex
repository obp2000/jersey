defmodule JerseyWeb.CustomerLive.Index do
  use JerseyWeb, :live_view

  alias Jersey.Customers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("customer", "Listing Customers"))
     |> stream(:customers, list_customers())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    customer = Customers.get_customer!(id)
    {:ok, _} = Customers.delete_customer(customer)

    {:noreply, stream_delete(socket, :customers, customer)}
  end

  defp list_customers() do
    Customers.list_customers()
  end
end
