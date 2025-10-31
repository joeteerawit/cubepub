defmodule Mix.Tasks.Cubepub.Setup.Admin do
  @moduledoc """
  Creates an admin user with default credentials.

  ## Usage

      mix cubepub.setup.admin

  ## Options

      --username USERNAME    Admin username (default: "admin")
      --password PASSWORD    Admin password (default: "changeme123")

  ## Examples

      # Create admin with default credentials
      mix cubepub.setup.admin

      # Create admin with custom credentials
      mix cubepub.setup.admin --username myadmin --password SecurePass123!

  ## Default Credentials

  If no options are provided, the following default credentials are used:
  - Username: admin
  - Password: changeme123

  ⚠️  IMPORTANT: Change the default password immediately after first login!
  """

  use Mix.Task

  alias Cubepub.Accounts.User

  @shortdoc "Creates an admin user with default or custom credentials"

  @default_username "admin"
  @default_password "changeme123"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _} =
      OptionParser.parse!(args,
        strict: [
          username: :string,
          password: :string
        ]
      )

    username = Keyword.get(opts, :username, @default_username)
    password = Keyword.get(opts, :password, @default_password)

    create_admin(username, password)
  end

  defp create_admin(username, password) do
    # Check if user already exists
    case Ash.read(User, authorize?: false) do
      {:ok, users} ->
        existing_user =
          Enum.find(users, fn user ->
            to_string(user.username) == username
          end)

        if existing_user do
          Mix.shell().error("""

          ❌ Admin user creation failed!

          A user with username '#{username}' already exists.

          Existing user details:
          - Username: #{existing_user.username}
          - Created: #{existing_user.created_at}
          """)

          {:error, :already_exists}
        else
          do_create_admin(username, password)
        end

      {:error, error} ->
        Mix.shell().error("Failed to check existing users: #{inspect(error)}")
        {:error, error}
    end
  end

  defp do_create_admin(username, password) do
    Mix.shell().info("\nCreating admin user...")

    case Ash.create(
           User,
           %{
             username: username,
             password: password,
             password_confirmation: password
           },
           action: :register_with_password,
           authorize?: false
         ) do
      {:ok, user} ->
        Mix.shell().info("""

        ✅ Admin user created successfully!

        ===========================================
        ADMIN USER CREDENTIALS
        ===========================================
        Username: #{user.username}
        Password: #{password}
        ===========================================

        ⚠️  IMPORTANT: Change this password immediately after first login!

        You can now log in at: /login
        """)

        {:ok, user}

      {:error, error} ->
        Mix.shell().error("""

        ❌ Failed to create admin user!

        Error: #{inspect(error, pretty: true)}

        Please check:
        - Database is running and migrations are up to date
        - Password meets requirements (if any)
        - Username is valid
        """)

        {:error, error}
    end
  end
end
