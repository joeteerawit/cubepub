defmodule Mix.Tasks.Cubepub.Setup.AdminTest do
  use Cubepub.DataCase

  alias Mix.Tasks.Cubepub.Setup.Admin, as: AdminTask
  alias Cubepub.Accounts.User

  describe "cubepub.setup.admin" do
    test "creates admin user with default credentials" do
      # Run the task
      AdminTask.run([])

      # Verify admin user was created
      {:ok, users} = Ash.read(User, authorize?: false)
      admin = Enum.find(users, fn u -> to_string(u.username) == "admin" end)

      assert admin
      assert to_string(admin.username) == "admin"
      assert admin.hashed_password
    end

    test "creates admin user with custom credentials" do
      AdminTask.run([
        "--username",
        "customadmin",
        "--password",
        "CustomPass123!"
      ])

      {:ok, users} = Ash.read(User, authorize?: false)
      admin = Enum.find(users, fn u -> to_string(u.username) == "customadmin" end)

      assert admin
      assert to_string(admin.username) == "customadmin"
    end

    test "fails when user already exists" do
      # Create a user first
      {:ok, _user} =
        Ash.create(
          User,
          %{
            username: "existingadmin",
            password: "Password123!",
            password_confirmation: "Password123!"
          },
          action: :register_with_password,
          authorize?: false
        )

      # Try to create admin with same username
      capture_io(fn ->
        {:error, :already_exists} =
          AdminTask.run(["--username", "existingadmin"])
      end)

      # Verify only one user with that username exists
      {:ok, users} = Ash.read(User, authorize?: false)
      matching_users = Enum.filter(users, fn u -> to_string(u.username) == "existingadmin" end)
      assert length(matching_users) == 1
    end

    test "can login with created admin credentials" do
      AdminTask.run(["--username", "logintest", "--password", "TestPass123!"])

      strategy = AshAuthentication.Info.strategy!(User, :password)

      {:ok, user} =
        AshAuthentication.Strategy.action(
          strategy,
          :sign_in,
          %{
            "username" => "logintest",
            "password" => "TestPass123!"
          },
          []
        )

      assert to_string(user.username) == "logintest"
    end
  end

  defp capture_io(fun) do
    ExUnit.CaptureIO.capture_io(fun)
  end
end
