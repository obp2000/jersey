defmodule JerseyWeb.PageController do
  use JerseyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
