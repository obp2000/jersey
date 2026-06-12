ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Jersey.Repo, :manual)

# Start Mox application for tests
Application.ensure_all_started(:mox)
