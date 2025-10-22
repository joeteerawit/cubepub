# Private Package Download Security

This document outlines the security mechanisms for preventing unauthorized downloads of private packages and the authentication flows for authorized access.

## Overview

Private packages require authentication and authorization before download. This ensures that only authorized users can access proprietary or sensitive packages.

## Authentication Methods

### 1. API Token Authentication
- User generates a token from the web dashboard
- Token is stored securely in the client configuration
- Token is sent with each download request

### 2. Session-Based Authentication
- User logs in via web interface
- Session cookie is used for downloads in browser
- Short-lived, suitable for web-based downloads

### 3. OAuth2 Integration
- For CI/CD and third-party integrations
- Token exchange with limited scopes
- Revokable access tokens

## Security Mechanisms

### Package Access Control
```
Private Package Access Flow:
1. Check if package is private
2. Verify authentication token/session
3. Check user permissions (ACL)
4. Validate rate limits
5. Log access attempt
6. Grant or deny download
```

### Token Types
- **Personal Access Tokens** - Long-lived, user-specific
- **Organization Tokens** - Shared within teams
- **Deployment Tokens** - Scoped to specific packages, read-only
- **CI/CD Tokens** - Time-limited, automated usage

## Sequence Diagrams

### 1. Unauthorized Download Attempt (Public Package)

```mermaid
sequenceDiagram
    participant Client as Flutter Client
    participant API as CubePub API
    participant DB as Database
    participant Storage as Package Storage

    Client->>API: GET /api/packages/my_package/download/1.0.0
    API->>DB: Check if package is public
    DB-->>API: Package is public
    API->>Storage: Retrieve package tarball
    Storage-->>API: Package data
    API-->>Client: 200 OK + Package tarball
    Note over Client: Download succeeds
```

### 2. Unauthorized Download Attempt (Private Package - Blocked)

```mermaid
sequenceDiagram
    participant Client as Flutter Client
    participant API as CubePub API
    participant DB as Database

    Client->>API: GET /api/packages/private_package/download/1.0.0
    Note over Client,API: No authentication token provided
    
    API->>DB: Check package visibility
    DB-->>API: Package is private
    
    API->>API: Verify authentication
    Note over API: No valid token found
    
    API-->>Client: 401 Unauthorized
    Note over Client: Download blocked with error message
```

### 3. Authorized Download with API Token

```mermaid
sequenceDiagram
    participant Client as Flutter Client
    participant API as CubePub API
    participant Auth as Auth Service
    participant ACL as Access Control
    participant DB as Database
    participant Storage as Package Storage
    participant Audit as Audit Log

    Client->>API: GET /api/packages/private_package/download/1.0.0<br/>Header: Authorization: Bearer <token>
    
    API->>Auth: Validate token
    Auth->>DB: Check token in database
    DB-->>Auth: Token valid, user_id: 123
    Auth-->>API: Token valid, user: john@example.com
    
    API->>DB: Check package visibility
    DB-->>API: Package is private
    
    API->>ACL: Check user permissions
    ACL->>DB: Query package ACL for user_id: 123
    DB-->>ACL: User has download permission
    ACL-->>API: Access granted
    
    API->>API: Check rate limits
    Note over API: User within rate limits
    
    API->>Storage: Retrieve package tarball
    Storage-->>API: Package data
    
    API->>Audit: Log download event
    Audit->>DB: Store audit log
    
    API-->>Client: 200 OK + Package tarball
    Note over Client: Download succeeds
```

### 4. Token Generation Flow

```mermaid
sequenceDiagram
    participant User as User (Browser)
    participant Web as Web Dashboard
    participant API as CubePub API
    participant Auth as Auth Service
    participant DB as Database

    User->>Web: Navigate to API Tokens page
    Web->>API: GET /api/user/tokens
    API->>DB: Fetch user's existing tokens
    DB-->>API: List of tokens (masked)
    API-->>Web: Token list
    Web-->>User: Display tokens

    User->>Web: Click "Generate New Token"
    Web->>User: Show token creation form<br/>(name, scopes, expiration)
    
    User->>Web: Submit form<br/>(name: "CI Token", scopes: ["read:packages"], expires: 90 days)
    
    Web->>API: POST /api/tokens<br/>{name, scopes, expiration}
    
    API->>Auth: Generate secure token
    Auth->>Auth: Create cryptographic token
    Auth-->>API: Token: cubepub_abc123...
    
    API->>DB: Store token (hashed)
    DB-->>API: Token saved
    
    API-->>Web: Token created successfully<br/>Token: cubepub_abc123...
    
    Web-->>User: Display token ONCE<br/>"Copy this token, it won't be shown again"
    
    Note over User: User copies token and<br/>stores in CI/CD environment
```

### 5. Package Resolution with Private Dependencies

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant CLI as Flutter CLI
    participant Config as .pub-cache/credentials
    participant API as CubePub API
    participant DB as Database

    Dev->>CLI: flutter pub get
    CLI->>CLI: Parse pubspec.yaml
    Note over CLI: Found dependency:<br/>private_package: ^1.0.0

    CLI->>Config: Read credentials for cubepub.dev
    Config-->>CLI: Token: cubepub_abc123...

    CLI->>API: GET /api/packages/private_package/versions/1.0.0<br/>Authorization: Bearer cubepub_abc123...
    
    API->>DB: Validate token & check permissions
    DB-->>API: Access granted
    
    API-->>CLI: Version metadata + download URL
    
    CLI->>API: GET /api/packages/private_package/download/1.0.0<br/>Authorization: Bearer cubepub_abc123...
    
    API->>DB: Verify permissions & log access
    API-->>CLI: Package tarball
    
    CLI->>CLI: Extract to .pub-cache
    CLI-->>Dev: Dependencies resolved successfully
```

### 6. Organization-Level Access Control

```mermaid
sequenceDiagram
    participant User as User
    participant API as CubePub API
    participant DB as Database
    participant ACL as ACL Service

    User->>API: Download private_package<br/>Authorization: Bearer <token>
    
    API->>DB: Get user from token
    DB-->>API: user_id: 123, email: user@example.com
    
    API->>DB: Get package ownership
    DB-->>API: Owner: org_acme_corp
    
    API->>ACL: Check access for user 123 to org_acme_corp packages
    
    ACL->>DB: Query organization membership
    DB-->>ACL: User is member with role: "developer"
    
    ACL->>DB: Query package-specific ACL
    DB-->>ACL: Package allows: ["owner", "admin", "developer"]
    
    ACL->>ACL: Match user role with allowed roles
    Note over ACL: "developer" is in allowed list
    
    ACL-->>API: Access GRANTED
    
    API-->>User: 200 OK + Package
```

### 7. Access Denied - Insufficient Permissions

```mermaid
sequenceDiagram
    participant User as User
    participant API as CubePub API
    participant DB as Database
    participant ACL as ACL Service
    participant Audit as Audit Log

    User->>API: Download private_package<br/>Authorization: Bearer <token>
    
    API->>DB: Get user from token
    DB-->>API: user_id: 456, email: external@example.com
    
    API->>DB: Get package ownership
    DB-->>API: Owner: org_acme_corp
    
    API->>ACL: Check access for user 456 to org_acme_corp packages
    
    ACL->>DB: Query organization membership
    DB-->>ACL: User is NOT a member
    
    ACL->>DB: Check if package allows public access
    DB-->>ACL: Package is private
    
    ACL-->>API: Access DENIED
    
    API->>Audit: Log unauthorized access attempt
    Audit->>DB: Store security event
    
    API-->>User: 403 Forbidden<br/>"You don't have permission to access this package"
```

## Implementation Details

### Token Storage Format

```json
{
  "token_id": "uuid-v4",
  "user_id": 123,
  "name": "CI Token",
  "token_hash": "bcrypt_hash_of_token",
  "scopes": ["read:packages", "write:packages"],
  "created_at": "2025-10-22T10:00:00Z",
  "expires_at": "2026-01-22T10:00:00Z",
  "last_used_at": "2025-10-22T15:30:00Z",
  "last_used_ip": "192.168.1.1"
}
```

### Client Configuration (~/.pub-cache/credentials.json)

```json
{
  "cubepub.dev": {
    "token": "cubepub_abc123def456...",
    "type": "Bearer",
    "added_at": "2025-10-22T10:00:00Z"
  },
  "pub.dev": {
    "token": "pub_xyz789...",
    "type": "Bearer"
  }
}
```

### API Request Headers

```http
GET /api/packages/private_package/download/1.0.0 HTTP/1.1
Host: cubepub.dev
Authorization: Bearer cubepub_abc123def456...
User-Agent: Dart pub 3.0.0
Accept: application/vnd.cubepub.v1+json
```

### Access Control List (ACL) Structure

```elixir
defmodule Cubepub.Packages.ACL do
  schema "package_acls" do
    belongs_to :package, Cubepub.Packages.Package
    field :type, Enum, values: [:user, :organization, :team, :public]
    field :subject_id, :integer  # user_id, org_id, or team_id
    field :permission, Enum, values: [:read, :write, :admin]
    
    timestamps()
  end
end
```

## Security Best Practices

### For Package Publishers

1. **Use scoped tokens** - Create tokens with minimal required permissions
2. **Rotate tokens regularly** - Set expiration dates and rotate before expiry
3. **Monitor token usage** - Review audit logs for suspicious activity
4. **Revoke unused tokens** - Remove tokens that are no longer needed
5. **Use deployment tokens for CI/CD** - Read-only tokens for automated systems

### For Package Consumers

1. **Store tokens securely** - Never commit tokens to version control
2. **Use environment variables** - In CI/CD, use secret management
3. **Limit token scope** - Only request permissions you need
4. **Report compromised tokens** - Immediately revoke if exposed
5. **Use different tokens per environment** - Dev, staging, production

### For System Administrators

1. **Implement rate limiting** - Prevent abuse and DDoS
2. **Enable audit logging** - Track all access attempts
3. **Set token expiration** - Force periodic rotation
4. **Monitor failed auth attempts** - Alert on suspicious patterns
5. **Encrypt tokens at rest** - Use strong hashing algorithms

## Rate Limiting

### Tier-Based Limits

```
Free Tier:
- 100 downloads per hour
- 1,000 downloads per day
- 2 concurrent downloads

Pro Tier:
- 1,000 downloads per hour
- 10,000 downloads per day
- 10 concurrent downloads

Enterprise:
- Unlimited downloads
- Custom rate limits
- Dedicated CDN
```

### Rate Limit Response

```http
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1698067200
Retry-After: 300

{
  "error": "rate_limit_exceeded",
  "message": "Download rate limit exceeded. Try again in 5 minutes.",
  "reset_at": "2025-10-22T16:00:00Z"
}
```

## Error Responses

### 401 Unauthorized
```json
{
  "error": "unauthorized",
  "message": "Authentication required. Please provide a valid API token.",
  "docs": "https://cubepub.dev/docs/authentication"
}
```

### 403 Forbidden
```json
{
  "error": "forbidden",
  "message": "You don't have permission to access this package.",
  "required_permission": "read:packages",
  "package": "private_package"
}
```

### 404 Not Found
```json
{
  "error": "not_found",
  "message": "Package not found or you don't have access to it.",
  "package": "private_package"
}
```

## Client Setup Guide

### Step 1: Generate Token

```bash
# Via Web Dashboard
1. Login to https://cubepub.dev
2. Navigate to Settings > API Tokens
3. Click "Generate New Token"
4. Set name, scopes, and expiration
5. Copy the token (shown only once)
```

### Step 2: Configure Flutter Client

```bash
# Add token to pub credentials
flutter pub token add https://cubepub.dev

# Or manually edit ~/.pub-cache/credentials.json
```

### Step 3: Configure pubspec.yaml

```yaml
name: my_app
dependencies:
  private_package:
    hosted:
      name: private_package
      url: https://cubepub.dev
    version: ^1.0.0
```

### Step 4: Install Dependencies

```bash
flutter pub get
```

## Monitoring and Alerts

### Security Events to Monitor

1. **Failed authentication attempts** - Multiple failures from same IP
2. **Token usage spikes** - Unusual download patterns
3. **Geographic anomalies** - Access from unexpected locations
4. **Expired token usage** - Attempts with expired tokens
5. **Permission escalation attempts** - Requests exceeding token scope

### Alert Thresholds

- 5+ failed auth attempts in 1 minute → Alert
- 100+ downloads in 1 minute from single token → Alert
- Access from new country → Notify user
- Token used after revocation → Alert + Block IP

## Audit Log Example

```json
{
  "event_id": "evt_123456",
  "timestamp": "2025-10-22T15:30:00Z",
  "event_type": "package.download",
  "actor": {
    "user_id": 123,
    "email": "user@example.com",
    "ip_address": "192.168.1.1",
    "user_agent": "Dart pub 3.0.0"
  },
  "resource": {
    "package": "private_package",
    "version": "1.0.0",
    "visibility": "private"
  },
  "outcome": "success",
  "metadata": {
    "token_id": "tok_abc123",
    "bytes_transferred": 1048576,
    "duration_ms": 150
  }
}
```
