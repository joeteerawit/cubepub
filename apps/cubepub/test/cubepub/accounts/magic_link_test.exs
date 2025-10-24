defmodule Cubepub.Accounts.MagicLinkTest do
  use Cubepub.DataCase

  alias Cubepub.Accounts.User

  describe "magic link authentication" do
    @valid_email "magicuser@example.com"

    test "requests a magic link for an existing user (password-based)" do
      # First, create a user with password
      assert {:ok, _user} =
               Ash.create(
                 User,
                 %{
                   email: @valid_email,
                   password: "SecurePassword123!",
                   password_confirmation: "SecurePassword123!"
                 },
                 action: :register_with_password,
                 authorize?: false
               )

      # Request a magic link for existing user
      strategy = AshAuthentication.Info.strategy!(User, :magic_link)

      assert :ok =
               AshAuthentication.Strategy.action(
                 strategy,
                 :request,
                 %{"email" => @valid_email},
                 []
               )
    end

    test "does not reveal if user exists (prevents email enumeration)" do
      strategy = AshAuthentication.Info.strategy!(User, :magic_link)
      non_existent_email = "nonexistent@example.com"

      # Magic link should return :ok even for non-existent users
      # (this prevents attackers from enumerating valid email addresses)
      assert :ok =
               AshAuthentication.Strategy.action(
                 strategy,
                 :request,
                 %{"email" => non_existent_email},
                 []
               )
    end

    test "fails to request magic link with invalid email" do
      strategy = AshAuthentication.Info.strategy!(User, :magic_link)

      assert {:error, _} =
               AshAuthentication.Strategy.action(
                 strategy,
                 :request,
                 %{"email" => ""},
                 []
               )
    end

    test "user can have both password and magic link authentication" do
      # Create user with password
      assert {:ok, user} =
               Ash.create(
                 User,
                 %{
                   email: "hybrid@example.com",
                   password: "SecurePassword123!",
                   password_confirmation: "SecurePassword123!"
                 },
                 action: :register_with_password,
                 authorize?: false
               )

      assert user.hashed_password != nil

      # Request magic link for the same user
      strategy = AshAuthentication.Info.strategy!(User, :magic_link)

      assert :ok =
               AshAuthentication.Strategy.action(
                 strategy,
                 :request,
                 %{"email" => "hybrid@example.com"},
                 []
               )
    end
  end
end
