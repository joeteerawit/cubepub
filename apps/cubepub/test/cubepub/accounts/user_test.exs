defmodule Cubepub.Accounts.UserAuthenticationTest do
  use Cubepub.DataCase

  alias Cubepub.Accounts.User

  describe "password authentication" do
    @valid_attrs %{
      email: "test@example.com",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!"
    }

    test "registers a new user with valid credentials" do
      assert {:ok, user} =
               Ash.create(User, @valid_attrs,
                 action: :register_with_password,
                 authorize?: false
               )

      assert to_string(user.email) == "test@example.com"
      assert user.hashed_password != nil
      assert user.hashed_password != "SecurePassword123!"
      assert user.id != nil
    end

    test "fails to register with mismatched password confirmation" do
      attrs = %{
        email: "test@example.com",
        password: "SecurePassword123!",
        password_confirmation: "DifferentPassword"
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(User, attrs,
                 action: :register_with_password,
                 authorize?: false
               )
    end

    test "fails to register with duplicate email" do
      # Create first user
      assert {:ok, _user} =
               Ash.create(User, @valid_attrs,
                 action: :register_with_password,
                 authorize?: false
               )

      # Try to create second user with same email
      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(User, @valid_attrs,
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
                   "email" => "test@example.com",
                   "password" => "SecurePassword123!"
                 },
                 []
               )

      assert to_string(authenticated_user.email) == "test@example.com"
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
                   "email" => "test@example.com",
                   "password" => "WrongPassword"
                 },
                 []
               )
    end

    test "fails to sign in with non-existent email" do
      strategy = AshAuthentication.Info.strategy!(User, :password)

      assert {:error, _} =
               AshAuthentication.Strategy.action(
                 strategy,
                 :sign_in,
                 %{
                   "email" => "nonexistent@example.com",
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

      # Verify password is hashed
      assert user.hashed_password != @valid_attrs.password
      assert String.starts_with?(user.hashed_password, "$2b$")
    end
  end
end
