defmodule JerseyWeb.CustomerLive.Show do
  use JerseyWeb, :live_view

  alias Jersey.Customers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("customer", "Show Customer"))
     |> assign(:customer, Customers.get_customer!(id))}
  end
end
