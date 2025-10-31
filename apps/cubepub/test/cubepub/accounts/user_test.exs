defmodule Cubepub.Accounts.UserAuthenticationTest do
  use Cubepub.DataCase

  alias Cubepub.Accounts.User

  describe "password authentication" do
    @valid_attrs %{
      username: "testuser",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!"
    }

    test "registers a new user with valid credentials" do
      assert {:ok, user} =
               Ash.create(User, @valid_attrs,
                 action: :register_with_password,
                 authorize?: false
               )

      assert to_string(user.username) == "testuser"
      assert user.hashed_password != nil
      assert user.hashed_password != "SecurePassword123!"
      assert user.id != nil
    end

    test "fails to register with mismatched password confirmation" do
      attrs = %{
        username: "testuser",
        password: "SecurePassword123!",
        password_confirmation: "DifferentPassword"
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(User, attrs,
                 action: :register_with_password,
                 authorize?: false
               )
    end

    test "fails to register with duplicate username" do
      # Create first user
      assert {:ok, _user} =
               Ash.create(User, @valid_attrs,
                 action: :register_with_password,
                 authorize?: false
               )

      # Try to create second user with same username
      attrs = %{
        username: "testuser",
        password: "SecurePassword123!",
        password_confirmation: "SecurePassword123!"
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(User, attrs,
                 action: :register_with_password,
                 authorize?: false
               )
    end

    test "signs in with correct password" do
      # First, register a user
      assert {:ok, _user} =
               Ash.create(User, @valid_attrs,
                 action: :register_with_password,
                 authorize?: false
               )

      # Now try to sign in using AshAuthentication.Strategy
      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:ok, authenticated_user} =
               AshAuthentication.Strategy.action(
                 strategy,
                 :sign_in,
                 %{
                   "username" => "testuser",
                   "password" => "SecurePassword123!"
                 },
                 []
               )

      assert to_string(authenticated_user.username) == "testuser"
    end

    test "fails to sign in with incorrect password" do
      # First, register a user
      assert {:ok, _user} =
               Ash.create(User, @valid_attrs,
                 action: :register_with_password,
                 authorize?: false
               )

      # Try to sign in with wrong password using AshAuthentication.Strategy
      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:error, %AshAuthentication.Errors.AuthenticationFailed{}} =
               AshAuthentication.Strategy.action(
                 strategy,
                 :sign_in,
                 %{
                   "username" => "testuser",
                   "password" => "WrongPassword"
                 },
                 []
               )
    end

    test "fails to sign in with non-existent username" do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:error, _} =
               AshAuthentication.Strategy.action(
                 strategy,
                 :sign_in,
                 %{
                   "username" => "nonexistentuser",
                   "password" => "SomePassword"
                 },
                 []
               )
    end

    test "password is hashed and not stored in plain text" do
      assert {:ok, user} =
               Ash.create(User, @valid_attrs,
                 action: :register_with_password,
                 authorize?: false
               )

      # Verify password is hashed with Argon2
      assert user.hashed_password != @valid_attrs.password
      assert String.starts_with?(user.hashed_password, "$argon2id$")
    end
  end
end
