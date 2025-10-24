defmodule Cubepub.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer],
    domain: Cubepub.Accounts

  postgres do
    table("users")
    repo(Cubepub.Repo)
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? true
      sensitive? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  authentication do
    tokens do
      enabled? true
      token_resource Cubepub.Accounts.Token
      store_all_tokens? true
      require_token_presence_for_authentication? true

      signing_secret fn _, _ ->
        Application.fetch_env(:cubepub, :token_signing_secret)
      end
    end

    strategies do
      password :password do
        identity_field :email
        hashed_password_field :hashed_password
      end

      magic_link :magic_link do
        identity_field :email
        token_lifetime {10, :minutes}

        sender fn user, token, _opts ->
          # You'll need to implement email sending here
          # For now, we'll just log the magic link
          IO.puts("""

          ==============================================
          Magic Link for #{user.email}:

          http://localhost:4000/auth/magic_link?token=#{token}

          This link will expire in 10 minutes.
          ==============================================

          """)

          {:ok, user}
        end
      end
    end
  end

  identities do
    identity :unique_email, [:email]
  end

  actions do
    defaults [:read, :destroy]

    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy always() do
      forbid_if always()
    end
  end
end
