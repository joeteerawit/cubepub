defmodule CubepubWeb.Live.LoginLive do
  use CubepubWeb, :login_live_view

  alias Cubepub.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"username" => "", "password" => ""}, as: :login))
      |> assign(:error_message, nil)
      |> assign(:show_password, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"login" => login_params}, socket) do
    form = to_form(login_params, as: :login)
    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event(
        "submit",
        %{"login" => %{"username" => username, "password" => password}} = _params,
        socket
      ) do
    strategy = AshAuthentication.Info.strategy!(User, :password)

    case AshAuthentication.Strategy.action(
           strategy,
           :sign_in,
           %{
             "username" => username,
             "password" => password
           },
           []
         ) do
      {:ok, user} ->
        # Generate token for the authenticated user (returns {token, claims})
        case AshAuthentication.Jwt.token_for_user(user) do
          {:ok, token, _claims} ->
            {:noreply,
             socket
             |> put_flash(:info, "Welcome back, #{user.username}!")
             |> redirect(external: "/auth/login?user_token=#{URI.encode_www_form(token)}")}

          {:error, _error} ->
            socket =
              socket
              |> assign(:error_message, "Authentication failed")
              |> assign(:form, to_form(%{"username" => "", "password" => ""}, as: :login))

            {:noreply, socket}
        end

      {:error, _error} ->
        socket =
          socket
          |> assign(:error_message, "Invalid username or password")
          |> assign(:form, to_form(%{"username" => username, "password" => ""}, as: :login))

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, :show_password, !socket.assigns.show_password)}
  end
end
