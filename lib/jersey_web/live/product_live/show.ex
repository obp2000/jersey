defmodule JerseyWeb.ProductLive.Show do
  use JerseyWeb, :live_view

  alias Jersey.Products

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("product", "Show Product"))
     |> assign(:product, Products.get_product!(id))}
  end
end
