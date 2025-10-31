defmodule CubepubWeb.Live.LoginLiveTest do
  use CubepubWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Cubepub.Accounts.User

  describe "Login page" do
    test "renders login form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/login")

      assert html =~ "Welcome Back"
      assert html =~ "Log in to access your Flutter packages"
      assert has_element?(view, "form#login-form")
      assert has_element?(view, "input#username")
      assert has_element?(view, "input#password")
      assert has_element?(view, "button[type=\"submit\"]", "Log In")
    end

    test "shows error message with invalid credentials", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/login")

      html =
        view
        |> form("#login-form", login: %{username: "nonexistent", password: "wrongpass"})
        |> render_submit()

      assert html =~ "Invalid username or password"
    end

    test "successfully logs in with valid credentials", %{conn: conn} do
      # Create a test user
      {:ok, _user} =
        Ash.create(
          User,
          %{
            username: "testlogin",
            password: "ValidPassword123!",
            password_confirmation: "ValidPassword123!"
          },
          action: :register_with_password,
          authorize?: false
        )

      {:ok, view, _html} = live(conn, ~p"/login")

      # Submit login form - should redirect to auth controller with token
      assert {:error, {:redirect, %{to: redirect_url}}} =
               view
               |> form("#login-form",
                 login: %{username: "testlogin", password: "ValidPassword123!"}
               )
               |> render_submit()

      # Verify redirect contains auth endpoint and token
      assert redirect_url =~ "/auth/login?user_token="
    end

    test "toggles password visibility", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/login")

      # Initially password field should be type="password"
      assert has_element?(view, "input#password[type=\"password\"]")

      # Click toggle button using phx-click attribute
      view |> element("button[phx-click=\"toggle_password\"]") |> render_click()

      # Password field should now be type="text"
      assert has_element?(view, "input#password[type=\"text\"]")

      # Click again to hide
      view |> element("button[phx-click=\"toggle_password\"]") |> render_click()

      # Password field should be type="password" again
      assert has_element?(view, "input#password[type=\"password\"]")
    end

    test "clears password field after failed login", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/login")

      form =
        view
        |> form("#login-form", login: %{username: "testuser", password: "wrongpass"})
        |> render_submit()

      # Username should be preserved
      assert form =~ "value=\"testuser\""

      # Password should be cleared
      refute form =~ "value=\"wrongpass\""
    end
  end
end
