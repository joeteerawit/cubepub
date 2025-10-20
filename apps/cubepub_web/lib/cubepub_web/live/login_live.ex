defmodule CubepubWeb.Live.LoginLive do
  use CubepubWeb, :login_live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
