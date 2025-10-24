defmodule Cubepub.Repo do
  # use Ecto.Repo,
  #   otp_app: :cubepub,
  #   adapter: Ecto.Adapters.Postgres
  use AshPostgres.Repo, otp_app: :cubepub

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end

  def installed_extensions do
    ["ash-functions", "citext"]
  end
end
