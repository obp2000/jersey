# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :jersey, :scopes,
  user: [
    default: true,
    module: Jersey.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Jersey.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :jersey,
  ecto_repos: [Jersey.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :jersey, JerseyWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: JerseyWeb.ErrorHTML, json: JerseyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Jersey.PubSub,
  live_view: [signing_salt: "GKsIndiz"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :jersey, Jersey.Mailer, adapter: Swoosh.Adapters.Local

config :jersey,
  postcalc_key: System.get_env("POSTCALC_KEY") || "test",
  postcalc_url: System.get_env("POSTCALC_URL") || "http://test.postcalc.ru",
  from_pindex: System.get_env("FROM_PINDEX") || "153038"

# Configure Gettext
config :jersey, JerseyWeb.Gettext,
  default_locale: "ru",
  locales: ~w(en fr de ru)

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  jersey: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  jersey: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
