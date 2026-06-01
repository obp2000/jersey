defmodule JerseyWeb.CityLive.Form do
  use JerseyWeb, :live_view

  alias Jersey.Customers
  alias Jersey.Customers.City

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
    city = Customers.get_city!(id)

    socket
    |> assign(:page_title, dgettext("city", "Edit City"))
    |> assign(:city, city)
    |> assign(:form, to_form(Customers.change_city(city)))
  end

  defp apply_action(socket, :new, _params) do
    city = %City{}

    socket
    |> assign(:page_title, dgettext("city", "New City"))
    |> assign(:city, city)
    |> assign(:form, to_form(Customers.change_city(city)))
  end

  @impl true
  def handle_event("validate", %{"city" => city_params}, socket) do
    changeset = Customers.change_city(socket.assigns.city, city_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"city" => city_params}, socket) do
    save_city(socket, socket.assigns.live_action, city_params)
  end

  defp save_city(socket, :edit, city_params) do
    case Customers.update_city(socket.assigns.city, city_params) do
      {:ok, city} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("city", "City updated successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, city))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_city(socket, :new, city_params) do
    case Customers.create_city(city_params) do
      {:ok, city} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("city", "City created successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, city))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _city), do: ~p"/cities"
  defp return_path("show", city), do: ~p"/cities/#{city}"
end
