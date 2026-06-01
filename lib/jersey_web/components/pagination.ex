defmodule JerseyWeb.Pagination do
  use JerseyWeb, :html

  embed_templates "pagination/*"

  attr :page_number, :integer, required: true
  attr :total_pages, :integer, required: true

  def pagination(assigns)

  defp pagination_path(page) do
    "?page=#{page}"
  end
end
