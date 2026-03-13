# Service Binding Preview

A simple Node.js application that displays environment variables in an elegant web interface.

## Features

- 🎨 Clean, modern UI with gradient design
- 🔧 Environment variable display
- 🐳 Docker support
- 🚀 GitHub Actions CI/CD pipeline
- 📊 Health check endpoint
- 🔒 Secure handling of sensitive data

## Quick Start

### Prerequisites

- Node.js 20+ (or Docker)
- npm or yarn

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/service-binding-preview.git
   cd service-binding-preview
   ```

2. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

3. Edit [.env](.env) with your values

4. Install dependencies:
   ```bash
   npm install
   ```

5. Start the server:
   ```bash
   npm start
   ```

6. Open [http://localhost:3000](http://localhost:3000)

### Using Docker

Build and run with Docker:

```bash
# Build the image
docker build -t service-binding-preview .

# Run the container
docker run -p 3000:3000 \
  -e APP_NAME="My App" \
  -e ENVIRONMENT="production" \
  -e API_KEY="your-api-key" \
  service-binding-preview
```

Or use Docker Compose:

```bash
docker-compose up
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_NAME` | Application name | `Service Binding Preview` |
| `ENVIRONMENT` | Environment (development/production) | `development` |
| `VERSION` | Application version | `1.0.0` |
| `PORT` | Server port | `3000` |
| `API_KEY` | API key for external services | `not-set` |
| `DATABASE_URL` | Database connection string | `not-set` |

See [.env.example](.env.example) for a complete template.

## API Endpoints

- `GET /` - Main web interface displaying environment variables
- `GET /health` - Health check endpoint (returns JSON)

## GitHub Actions & GHCR

This project includes a GitHub Actions workflow that automatically builds and pushes Docker images to GitHub Container Registry (GHCR).

### Setup Instructions

1. **Enable GitHub Packages**: The workflow uses the default `GITHUB_TOKEN`, which has permission to push to GHCR

2. **Trigger Workflow**:
   - Push to `main` or `develop` branch
   - Create a tag with format `v*.*.*` (e.g., `v1.0.0`)
   - Manually trigger via GitHub Actions UI

3. **Pull the Image**:
   ```bash
   # Login to GHCR
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

   # Pull the image
   docker pull ghcr.io/YOUR_USERNAME/service-binding-preview:latest

   # Run it
   docker run -p 3000:3000 ghcr.io/YOUR_USERNAME/service-binding-preview:latest
   ```

### Workflow Features

- ✅ Multi-platform builds (amd64, arm64)
- ✅ Automatic tagging (branch, PR, semver, SHA)
- ✅ Build caching for faster builds
- ✅ Build attestation for security
- ✅ Only pushes on main branch (not PRs)

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── docker-build.yml   # CI/CD pipeline
├── server.js                  # Main application
├── package.json              # Dependencies
├── Dockerfile                # Container image
├── .dockerignore            # Docker ignore rules
├── .env                     # Local environment (gitignored)
├── .env.example             # Environment template
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## Development

The application uses vanilla Node.js with no framework dependencies (except dotenv for environment management). This keeps it lightweight and easy to understand.

## Security

- Sensitive values (API keys, database URLs) are masked in the UI
- Docker container runs as non-root user
- `.env` file is gitignored to prevent committing secrets
- Always use `.env.example` as a template

## License

MIT License
