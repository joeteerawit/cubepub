defmodule CubepubWeb.Live.ProjectDashboardLive do
  use CubepubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    new_socket =
      socket
      |> assign(current_path: "/")

    {:ok, new_socket}
  end
end
