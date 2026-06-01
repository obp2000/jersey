defmodule JerseyWeb.CityLive.Index do
  use JerseyWeb, :live_view

  alias Jersey.Customers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("city", "Listing Cities"))
     |> stream(:cities, list_cities())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    city = Customers.get_city!(id)

    {:noreply,
     case Customers.delete_city(city) do
       {:ok, _city} ->
         stream_delete(socket, :cities, city)

       {:error, %Ecto.Changeset{errors: errors} = _changeset} ->
         put_flash(socket, :error, errors[:customers] |> translate_error())
     end}
  end

  defp list_cities() do
    Customers.list_cities()
  end
end
