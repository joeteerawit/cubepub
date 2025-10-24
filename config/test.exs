import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :cubepub, Cubepub.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cubepub_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Configure token signing secret for AshAuthentication
config :cubepub, :token_signing_secret, "PbYvd6w0VynueRKq2En/e+GLtYEhdIc1p7jK0S9FAKZjIBLi4P9GOIF9DN6fF1zh"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cubepub_web, CubepubWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "PbYvd6w0VynueRKq2En/e+GLtYEhdIc1p7jK0S9FAKZjIBLi4P9GOIF9DN6fF1zh",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :cubepub, Cubepub.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
