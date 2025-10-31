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

    attribute :username, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? false
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
        identity_field :username
        hashed_password_field :hashed_password
        hash_provider AshAuthentication.Argon2Provider
      end
    end
  end

  identities do
    identity :unique_username, [:username]
  end

  actions do
    defaults [:read, :destroy]

    create :register_with_password do
      description "Register a new user with username and password"
      accept [:username]
      argument :password, :string, allow_nil?: false, sensitive?: true
      argument :password_confirmation, :string, allow_nil?: false, sensitive?: true

      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation
      change AshAuthentication.GenerateTokenChange
      change AshAuthentication.Strategy.Password.HashPasswordChange
    end

    read :sign_in_with_password do
      description "Sign in with username and password"
      argument :username, :ci_string, allow_nil?: false
      argument :password, :string, allow_nil?: false, sensitive?: true

      prepare AshAuthentication.Strategy.Password.SignInPreparation
    end

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
