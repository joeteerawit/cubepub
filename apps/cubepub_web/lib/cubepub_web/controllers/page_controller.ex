defmodule CubepubWeb.PageController do
  use CubepubWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
