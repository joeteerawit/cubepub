# Flutter Pub Client Authentication Flow

This document explains how Flutter's pub client handles authentication when downloading packages from a private repository like CubePub, and how the pubspec.yaml file works with the credential system.

## Key Concept: Separation of Concerns

**Important**: Authentication tokens are **NEVER** stored in `pubspec.yaml`. The pubspec file only declares dependencies, while credentials are stored separately in a secure location.

## The Two-Part System

### Part 1: pubspec.yaml (Public, Checked into Git)

```yaml
name: my_app
version: 1.0.0

dependencies:
  # Public package from pub.dev (default)
  http: ^1.1.0
  
  # Private package from CubePub
  cubepub_client:
    hosted:
      name: cubepub_client
      url: http://localhost:4000  # Your CubePub server
    version: ^1.58.0
  
  # Another private package from CubePub
  internal_utils:
    hosted:
      name: internal_utils
      url: https://cubepub.mycompany.com
    version: ^2.0.0
```

**This file is safe to commit to version control** - it contains no secrets!

### Part 2: credentials.json (Private, NOT in Git)

Located at: `~/.pub-cache/credentials.json`

```json
{
  "http://localhost:4000": {
    "token": "cubepub_abc123def456...",
    "env": "TOKEN"
  },
  "https://cubepub.mycompany.com": {
    "token": "cubepub_prod_xyz789...",
    "env": "PROD_TOKEN"
  },
  "https://pub.dev": {
    "token": "pub_official_token...",
    "env": "PUB_TOKEN"
  }
}
```

**This file is automatically managed by the pub client and should NEVER be committed to version control.**

## Complete Workflow

### Initial Setup (One-Time Per Developer)

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant CLI as Flutter CLI
    participant Creds as ~/.pub-cache/credentials.json
    participant Web as CubePub Web Dashboard
    participant API as CubePub API

    Note over Dev,API: Step 1: Generate Token

    Dev->>Web: Login to https://cubepub.dev
    Web->>Dev: Navigate to Settings > API Tokens
    Dev->>Web: Click "Generate New Token"
    Web->>API: POST /api/tokens {name, scopes, expiry}
    API-->>Web: Token: cubepub_abc123...
    Web-->>Dev: Display token (COPY NOW!)
    
    Note over Dev,API: Step 2: Store Token Locally

    Dev->>CLI: flutter pub token add http://localhost:4000
    CLI->>Dev: Prompt: "Enter token for http://localhost:4000:"
    Dev->>CLI: Paste: cubepub_abc123...
    
    CLI->>Creds: Write credentials
    Note over Creds: {<br/>  "http://localhost:4000": {<br/>    "token": "cubepub_abc123..."<br/>  }<br/>}
    
    CLI-->>Dev: ✓ Token saved successfully
    
    Note over Dev: Setup complete!<br/>Token never appears in pubspec.yaml
```

### Daily Development (Automatic)

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant CLI as Flutter CLI
    participant Pubspec as pubspec.yaml
    participant Creds as credentials.json
    participant API as CubePub API
    participant DB as Database

    Dev->>CLI: flutter pub get
    
    CLI->>Pubspec: Read dependencies
    Pubspec-->>CLI: cubepub_client from<br/>http://localhost:4000
    
    CLI->>Creds: Lookup token for http://localhost:4000
    Creds-->>CLI: Token: cubepub_abc123...
    
    CLI->>API: GET /api/packages/cubepub_client/versions<br/>Authorization: Bearer cubepub_abc123...
    
    API->>API: Validate token
    API->>DB: Check package access
    
    alt Package is Private & User Authorized
        DB-->>API: Access granted
        API-->>CLI: Version metadata
        
        CLI->>API: GET /api/packages/cubepub_client/download/1.58.0<br/>Authorization: Bearer cubepub_abc123...
        API-->>CLI: Package tarball
        
        CLI->>CLI: Extract to .pub-cache
        CLI-->>Dev: ✓ Dependencies resolved
    else Package is Private & User NOT Authorized
        DB-->>API: Access denied
        API-->>CLI: 403 Forbidden
        CLI-->>Dev: ✗ Error: No permission to access cubepub_client
    end
```

### Team Onboarding

```mermaid
sequenceDiagram
    participant New as New Team Member
    participant Team as Team Lead
    participant Docs as Team Docs
    participant CLI as Flutter CLI
    participant Git as Git Repository

    Team->>New: Welcome! Here's the setup guide
    New->>Docs: Read onboarding documentation
    
    Note over New: Step 1: Clone repo
    New->>Git: git clone repo
    Git-->>New: pubspec.yaml (with hosted URLs)
    
    Note over New: Step 2: Get CubePub token
    Docs-->>New: "Generate token at https://cubepub.dev/tokens"
    New->>New: Generate personal token
    
    Note over New: Step 3: Configure credentials
    New->>CLI: flutter pub token add http://localhost:4000
    CLI->>New: Enter token:
    New->>CLI: [paste token]
    CLI-->>New: ✓ Token saved
    
    Note over New: Step 4: Install dependencies
    New->>CLI: flutter pub get
    CLI-->>New: ✓ All dependencies resolved
    
    Note over New: Ready to develop!<br/>Token is secure and never shared
```

## CI/CD Setup

For continuous integration, tokens are stored as environment variables:

```mermaid
sequenceDiagram
    participant Dev as DevOps Engineer
    participant CI as CI/CD Platform
    participant Secret as Secret Manager
    participant Runner as CI Runner
    participant API as CubePub API

    Note over Dev,API: Setup Phase

    Dev->>CI: Configure environment variables
    Dev->>Secret: Store CUBEPUB_TOKEN secret
    Secret-->>CI: Secret available to runners

    Note over Dev,API: Build Phase (Every Commit)

    activate Runner
    Runner->>CI: Start build
    Runner->>Secret: Get CUBEPUB_TOKEN
    Secret-->>Runner: cubepub_ci_token_xyz...
    
    Runner->>Runner: Export PUB_HOSTED_URL_TOKEN=<token>
    Note over Runner: Or use: flutter pub token add --env-var CUBEPUB_TOKEN
    
    Runner->>Runner: flutter pub get
    
    Runner->>API: Download dependencies<br/>Authorization: Bearer <token>
    API-->>Runner: Packages
    
    Runner->>Runner: flutter build
    Runner-->>CI: ✓ Build successful
    deactivate Runner
```

### CI/CD Configuration Examples

#### GitHub Actions
```yaml
name: Build
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
      
      - name: Configure CubePub credentials
        env:
          CUBEPUB_TOKEN: ${{ secrets.CUBEPUB_TOKEN }}
        run: |
          flutter pub token add http://localhost:4000 --env-var CUBEPUB_TOKEN
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build
        run: flutter build apk
```

#### GitLab CI
```yaml
build:
  image: cirrusci/flutter:stable
  before_script:
    - flutter pub token add http://localhost:4000 --env-var CUBEPUB_TOKEN
  script:
    - flutter pub get
    - flutter build apk
  variables:
    CUBEPUB_TOKEN: $CUBEPUB_TOKEN
```

## Server Implementation

### Request Validation in CubePub

```elixir
defmodule CubepubWeb.PackageController do
  use CubepubWeb, :controller
  
  def download(conn, %{"name" => name, "version" => version}) do
    with {:ok, token} <- extract_token(conn),
         {:ok, user} <- authenticate_token(token),
         {:ok, package} <- get_package(name, version),
         :ok <- authorize_download(user, package) do
      
      # Log the download
      log_download(user, package)
      
      # Stream the package file
      send_download(conn, package.tarball_path)
    else
      {:error, :no_token} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})
      
      {:error, :invalid_token} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid or expired token"})
      
      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "No permission to access this package"})
      
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Package not found"})
    end
  end
  
  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> {:error, :no_token}
    end
  end
  
  defp authenticate_token(token) do
    case Cubepub.Accounts.verify_api_token(token) do
      {:ok, user} -> {:ok, user}
      {:error, _} -> {:error, :invalid_token}
    end
  end
  
  defp authorize_download(user, package) do
    if Cubepub.Packages.can_download?(user, package) do
      :ok
    else
      {:error, :forbidden}
    end
  end
end
```

### Token Validation

```elixir
defmodule Cubepub.Accounts do
  def verify_api_token(token) do
    with {:ok, token_hash} <- hash_token(token),
         %Token{} = db_token <- Repo.get_by(Token, token_hash: token_hash),
         :ok <- check_expiration(db_token),
         :ok <- check_scopes(db_token, ["read:packages"]) do
      
      # Update last_used_at
      update_token_usage(db_token)
      
      # Return the user
      {:ok, Repo.preload(db_token, :user).user}
    else
      _ -> {:error, :invalid_token}
    end
  end
  
  defp check_expiration(%Token{expires_at: expires_at}) do
    if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
      :ok
    else
      {:error, :expired}
    end
  end
end
```

### Package Access Control

```elixir
defmodule Cubepub.Packages do
  def can_download?(user, package) do
    cond do
      # Public packages are accessible to everyone
      package.visibility == :public ->
        true
      
      # Package owner always has access
      package.user_id == user.id ->
        true
      
      # Check organization membership
      belongs_to_package_org?(user, package) ->
        true
      
      # Check explicit ACL
      has_package_permission?(user, package, :read) ->
        true
      
      # Default deny
      true ->
        false
    end
  end
end
```

## Security Considerations

### What Goes Where

| Information | Location | Safe to Commit? |
|-------------|----------|-----------------|
| Package name | pubspec.yaml | ✅ Yes |
| Package version | pubspec.yaml | ✅ Yes |
| Server URL | pubspec.yaml | ✅ Yes |
| API Token | credentials.json | ❌ NO! |
| User email | credentials.json | ❌ NO! |

### Best Practices

1. **Never commit credentials.json** - Add to `.gitignore`:
   ```gitignore
   # Never commit pub credentials
   .pub-cache/credentials.json
   ```

2. **Use environment variables in CI/CD**:
   ```bash
   export PUB_HOSTED_URL="http://localhost:4000"
   export PUB_HOSTED_URL_TOKEN="cubepub_token..."
   ```

3. **Rotate tokens regularly** - Set expiration dates and rotate before expiry

4. **Use scoped tokens** - Create tokens with minimal permissions:
   - Read-only for CI/CD
   - Read/Write for publishing

5. **Monitor token usage** - Track and alert on suspicious activity

## Troubleshooting

### Error: "Authentication required"

```bash
# Check if token is configured
flutter pub token list

# If not configured, add it
flutter pub token add http://localhost:4000

# Verify it works
flutter pub get
```

### Error: "No permission to access package"

```bash
# Verify your account has access
# Check with your admin or package owner

# Try refreshing the token
flutter pub token remove http://localhost:4000
flutter pub token add http://localhost:4000
```

### Error: "Invalid or expired token"

```bash
# Generate a new token from the web dashboard
# Then update the local credentials
flutter pub token remove http://localhost:4000
flutter pub token add http://localhost:4000
# Paste the new token
```

## How CubePub Server Knows Which Package

The pub client sends the package information in the URL path:

```http
GET /api/packages/cubepub_client/versions/1.58.0 HTTP/1.1
Host: localhost:4000
Authorization: Bearer cubepub_abc123def456...
Accept: application/vnd.pub.v2+json
User-Agent: Dart pub 3.0.0
```

The server:
1. Extracts `cubepub_client` from the URL path
2. Extracts the token from the `Authorization` header
3. Validates the token to identify the user
4. Checks if the user can access `cubepub_client`
5. Returns the package if authorized, or 403 if not

## Summary

✅ **pubspec.yaml**: Declares dependencies with server URLs (safe to commit)

✅ **credentials.json**: Stores authentication tokens (NEVER commit)

✅ **flutter pub token**: Command to manage credentials securely

✅ **Automatic**: The pub client automatically includes tokens when downloading

✅ **Secure**: Tokens never appear in pubspec.yaml or git history

✅ **Team-friendly**: Each developer has their own token

✅ **CI/CD-ready**: Use environment variables for automation

This separation ensures that your authentication credentials remain secure while your project configuration can be safely shared in version control.
