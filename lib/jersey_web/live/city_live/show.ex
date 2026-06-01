defmodule JerseyWeb.CityLive.Show do
  use JerseyWeb, :live_view

  alias Jersey.Customers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("city", "Show City"))
     |> assign(:city, Customers.get_city!(id))}
  end
end
