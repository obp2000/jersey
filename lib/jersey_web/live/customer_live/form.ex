defmodule JerseyWeb.CustomerLive.Form do
  use JerseyWeb, :live_view
  import LiveSelect

  alias Jersey.Customers
  alias Customers.Customer

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
    customer = Customers.get_customer!(id)

    socket
    |> assign(:page_title, dgettext("customer", "Edit Customer"))
    |> assign(:customer, customer)
    |> assign(:form, to_form(Customers.change_customer(customer)))
  end

  defp apply_action(socket, :new, _params) do
    customer = %Customer{}

    socket
    |> assign(:page_title, dgettext("customer", "New Customer"))
    |> assign(:customer, customer)
    |> assign(:form, to_form(Customers.change_customer(customer)))
  end

  @impl true
  def handle_event("validate", %{"customer" => customer_params}, socket) do
    changeset = Customers.change_customer(socket.assigns.customer, customer_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"customer" => customer_params}, socket) do
    save_customer(socket, socket.assigns.live_action, customer_params)
  end

  @impl true
  def handle_event(
        "live_select_change",
        %{"text" => text, "id" => live_select_id},
        socket
      ) do
    options = Customers.search_cities(text) |> Enum.map(&city_option/1)
    send_update(LiveSelect.Component, id: live_select_id, options: options)
    {:noreply, socket}
  end

  defp save_customer(socket, :edit, customer_params) do
    case Customers.update_customer(socket.assigns.customer, customer_params) do
      {:ok, customer} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("customer", "Customer updated successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, customer))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_customer(socket, :new, customer_params) do
    case Customers.create_customer(customer_params) do
      {:ok, customer} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("customer", "Customer created successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, customer))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _customer), do: ~p"/customers"
  defp return_path("show", customer), do: ~p"/customers/#{customer}"

  def city_value_mapper(nil), do: nil
  def city_value_mapper(""), do: nil

  def city_value_mapper(id) when is_integer(id) or is_binary(id) do
    Customers.get_city!(id) |> city_option()
  end

  def city_value_mapper(city) do
    city |> city_option()
  end

  defp city_option(city) do
    %{
      label: Customers.full_city_name(city),
      value: city.id
    }
  end
end
