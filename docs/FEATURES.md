# CubePub Features

A comprehensive Flutter pub package hosting system with public and private package management.

## Public Features (No Authentication Required)

### Package Discovery & Information
- **Browse public packages** - List and search available packages
- **Package details page** - View package metadata, description, and documentation
- **Version history** - See all published versions of a package
- **Dependency information** - View package dependencies and dependents
- **Download statistics** - Public download counts and popularity metrics
- **README rendering** - Display package README with markdown support
- **Changelog viewing** - Access version changelogs
- **License information** - View package licenses
- **Example code** - Browse example implementations
- **API documentation** - Access generated API docs
- **Package scoring** - See package health scores (likes, pub points)

### Search & Discovery
- **Full-text search** - Search packages by name, description, keywords
- **Filter by platform** - Android, iOS, Web, Windows, macOS, Linux
- **Sort options** - By relevance, popularity, recently updated, newest
- **Tag/category browsing** - Navigate packages by categories

### Package Access
- **Download public packages** - Open access to all public packages
- **View package source** - Browse package source code
- **Install instructions** - Get setup and installation guides

## Private Features (Authentication Required)

### Package Management
- **Publish packages** - Upload new packages or versions
- **Unpublish/retract versions** - Remove specific versions
- **Package ownership** - Manage who can publish to a package
- **Private packages** - Packages only accessible to authorized users
- **Access control lists (ACLs)** - Define who can download private packages
- **Package visibility settings** - Toggle between public/private
- **Version pre-releases** - Publish beta/alpha versions
- **Package transfer** - Transfer ownership between users/organizations
- **Package deprecation** - Mark packages as deprecated with migration paths

### User & Organization Management
- **User registration/login** - Authentication system
- **API tokens/keys** - Generate tokens for CI/CD publishing
- **Organization accounts** - Manage team-owned packages
- **Team member roles** - Owner, admin, publisher, viewer
- **User profiles** - Manage personal information and packages
- **Activity dashboard** - View personal package activities
- **Invite system** - Invite team members to organizations

### Security & Compliance
- **Security scanning** - Automated vulnerability detection
- **Security reports** - View and manage security issues
- **Package verification** - Verify package publishers
- **2FA/MFA support** - Enhanced account security
- **Audit logs** - Track package changes and access
- **Download restrictions** - Limit downloads by IP, domain, or user
- **License compliance tracking** - Monitor dependency licenses
- **Signature verification** - Verify package integrity and authenticity
- **SBOM (Software Bill of Materials)** - Generate and access package SBOMs

### Analytics & Monitoring
- **Detailed analytics** - Downloads by version, platform, geography
- **Usage metrics** - API usage tracking
- **Dependency impact analysis** - See which packages depend on yours
- **Email notifications** - New versions, security alerts, dependency updates
- **Webhooks** - Integrate with CI/CD pipelines
- **Custom reports** - Generate usage and adoption reports
- **Bandwidth monitoring** - Track data transfer usage

### Private Package Access
- **Download private packages** - Access authorized private packages
- **Scoped packages** - Namespace packages by organization
- **Private registries** - Isolated package registries per organization
- **Token-based access** - Use tokens for CI/CD package downloads

### Administrative Features (Admin Only)
- **Package moderation** - Review and approve packages
- **User management** - Suspend/ban users, manage permissions
- **Storage management** - Monitor and manage storage quotas
- **System configuration** - Server settings and policies
- **Backup & restore** - Data management and recovery
- **Rate limiting** - Configure API rate limits
- **Cache management** - Manage package cache and CDN settings

## Hybrid Features (Enhanced When Authenticated)

### Community Engagement
- **Package favorites/likes** - Public count visible, authenticated users can like
- **Package comments/ratings** - Public viewing, authenticated posting
- **Follow packages** - Get notified of updates (requires auth)
- **Follow publishers** - Track new packages from favorite authors

### Enhanced Discovery
- **Personalized recommendations** - AI-based package suggestions (requires auth)
- **Usage history** - Track your downloaded/used packages (requires auth)
- **Saved searches** - Save and reuse search queries (requires auth)

## API Features

### Public API Endpoints
- `GET /api/packages` - List public packages
- `GET /api/packages/:name` - Get package details
- `GET /api/packages/:name/versions/:version` - Get version metadata
- `GET /api/packages/:name/download/:version` - Download package tarball
- `GET /api/search` - Search packages

### Authenticated API Endpoints
- `POST /api/packages` - Publish a new package
- `POST /api/packages/:name/versions` - Publish a new version
- `DELETE /api/packages/:name/versions/:version` - Unpublish version
- `PUT /api/packages/:name/settings` - Update package settings
- `GET /api/user/packages` - List user's packages
- `POST /api/tokens` - Generate API tokens
- `GET /api/analytics/:name` - Get package analytics

## Client Features (Flutter CLI Integration)

### Package Resolution
- **pub get** - Resolve and download dependencies from CubePub
- **pub upgrade** - Upgrade packages to latest compatible versions
- **pub publish** - Publish packages to CubePub
- **Custom registry configuration** - Configure CubePub as package source

### Authentication
- **Token storage** - Securely store authentication tokens
- **Multi-registry support** - Use both pub.dev and CubePub simultaneously
- **Credential management** - Manage multiple registry credentials

## Future Enhancements

### Planned Features
- **Package mirrors** - Mirror packages from pub.dev
- **Automatic vulnerability scanning** - Integration with CVE databases
- **Package signing** - Cryptographic signing of packages
- **GraphQL API** - Modern API alternative to REST
- **Package badges** - Embeddable status badges
- **CI/CD integrations** - GitHub Actions, GitLab CI templates
- **Package templates** - Starter templates for new packages
- **Package playground** - Online editor to try packages
- **Dependency graphs** - Visual dependency tree exploration
- **Package comparison** - Side-by-side package comparison tool
