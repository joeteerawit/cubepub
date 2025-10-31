defmodule CubepubWeb.AuthController do
  use CubepubWeb, :controller

  def login(conn, %{"user_token" => token}) do
    conn
    |> put_session(:user_token, token)
    |> put_flash(:info, "Logged in successfully!")
    |> redirect(to: ~p"/")
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: ~p"/login")
  end
end
