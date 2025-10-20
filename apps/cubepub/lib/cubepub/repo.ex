defmodule Cubepub.Repo do
  use Ecto.Repo,
    otp_app: :cubepub,
    adapter: Ecto.Adapters.Postgres
end
