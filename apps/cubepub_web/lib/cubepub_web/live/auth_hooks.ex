defmodule CubepubWeb.Live.AuthHooks do
  @moduledoc """
  LiveView authentication hooks for protecting routes.
  """
  import Phoenix.Component
  import Phoenix.LiveView
  use CubepubWeb, :verified_routes

  alias Cubepub.Accounts.User

  def on_mount(:require_authenticated_user, _params, session, socket) do
    socket =
      socket
      |> assign_new(:current_user, fn -> get_user_from_session(session) end)

    case socket.assigns.current_user do
      nil ->
        socket =
          socket
          |> put_flash(:error, "You must log in to access this page.")
          |> redirect(to: ~p"/login")

        {:halt, socket}

      _user ->
        {:cont, socket}
    end
  end

  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    socket =
      socket
      |> assign_new(:current_user, fn -> get_user_from_session(session) end)

    case socket.assigns.current_user do
      nil ->
        {:cont, socket}

      _user ->
        {:halt, redirect(socket, to: ~p"/")}
    end
  end

  defp get_user_from_session(session) do
    case session["user_token"] do
      nil ->
        nil

      token ->
        # First verify the JWT token to get the claims
        case AshAuthentication.Jwt.verify(token, User) do
          {:ok, %{"sub" => subject}, _jti} ->
            # Then use subject_to_user to get the actual user record
            case AshAuthentication.subject_to_user(subject, User) do
              {:ok, user} -> user
              {:error, _} -> nil
            end

          {:error, _} ->
            nil
        end
    end
  end
end
