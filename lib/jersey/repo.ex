defmodule Jersey.Repo do
  use Ecto.Repo,
    otp_app: :jersey,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 5
end
