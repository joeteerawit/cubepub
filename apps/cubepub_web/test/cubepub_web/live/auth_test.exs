defmodule CubepubWeb.Live.AuthTest do
  use CubepubWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Cubepub.Accounts.User

  setup do
    # Create a test user bypassing authorization for test setup
    {:ok, user} =
      User
      |> Ash.Changeset.for_create(:register_with_password, %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      })
      |> Ash.create(authorize?: false)

    %{user: user}
  end

  describe "authentication guards" do
    test "redirects to login when accessing protected routes without authentication", %{conn: conn} do
      # Try to access dashboard without being logged in
      {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/")

      # Verify the redirect actually works
      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/login"
    end

    test "allows access to login page when not authenticated", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/login")
      assert html =~ "Welcome Back"
    end

    test "redirects authenticated users away from login page", %{conn: conn, user: user} do
      # Generate token for authenticated user
      {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)

      # Store token in session
      conn = conn |> init_test_session(%{}) |> put_session(:user_token, token)

      # Try to access login page
      {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/login")

      # Verify the redirect works
      conn = get(conn, ~p"/login")
      assert redirected_to(conn) == ~p"/"
    end

    test "allows authenticated users to access protected routes", %{conn: conn, user: user} do
      # Generate token for authenticated user
      {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)

      # Store token in session
      conn = conn |> init_test_session(%{}) |> put_session(:user_token, token)

      # Access dashboard
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "Dashboard"
    end

    test "logout clears session and redirects to login", %{conn: conn, user: user} do
      # Generate token for authenticated user
      {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)

      # Store token in session
      conn = conn |> init_test_session(%{}) |> put_session(:user_token, token)

      # Logout
      conn = delete(conn, ~p"/logout")
      assert redirected_to(conn) == ~p"/login"

      # Verify session is cleared - try accessing protected route
      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/login"
    end

    test "login flow stores token in session and redirects to dashboard", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/login")

      # Submit login form - should redirect with token
      assert {:error, {:redirect, %{to: redirect_url}}} =
               view
               |> form("#login-form", login: %{username: "testuser", password: "password123"})
               |> render_submit()

      # Verify redirect URL contains the auth endpoint and token
      assert redirect_url =~ "/auth/login?user_token="
    end
  end
end
