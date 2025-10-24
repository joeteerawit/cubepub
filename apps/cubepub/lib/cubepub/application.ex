defmodule Cubepub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Cubepub.Repo,
      {DNSCluster, query: Application.get_env(:cubepub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Cubepub.PubSub},
      {AshAuthentication.Supervisor, otp_app: :cubepub},
      # Start a worker by calling: Cubepub.Worker.start_link(arg)
      # {Cubepub.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Cubepub.Supervisor)
  end
end
