[![Kitsu](https://zou.cg-wire.com/kitsu.png)](https://kitsu.cg-wire.com)

# Kitsu, Collaboration Platform for Animation, VFX, and Video Game Studios

Kitsu is a web application that allows you to collaborate on your creative productions and
manage your deliveries. It improves the communication between all stakeholders.
Which leads to better results and faster shipping.

[![CI badge](https://github.com/cgwire/kitsu/actions/workflows/ci.yml/badge.svg)](https://github.com/cgwire/kitsu/actions/workflows/ci.yml)
[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.com/invite/VbCxtKN)
[![Donation](https://img.shields.io/liberapay/receives/CGWire.svg?logo=liberapay">)](https://liberapay.com/CGWire/donate)

## Overview

This repository contains the **Kitsu frontend** (Vue.js SPA). It requires a [Zou backend](https://github.com/cgwire/zou) to function.

```
┌─────────────┐      ┌─────────────┐
│   Kitsu     │ ──►  │    Zou      │
│  (Frontend) │      │  (Backend)  │
│  Port 8080  │      │ Port 5000/1 │
└─────────────┘      └─────────────┘
```

## Prerequisites

- **Zou backend** running and accessible (see [Zou repository](https://github.com/cgwire/zou))
- Node.js 20+ (for local development)
- Docker & Docker Compose (for containerized deployment)

## Quick Start

### Development

```bash
# Install dependencies
npm install

# Start dev server (connects to Zou at http://localhost:5000)
npm run dev
```

Or using Docker:

```bash
# Copy and configure .env file
cp .env.example .env
# Edit .env with your Zou backend URLs

# Start development container (automatically loads .env)
docker compose up kitsu-dev
```

Access at `http://localhost:8080`

### Production

```bash
# Build
npm run build

# Preview production build
npm run preview
```

Or using Docker:

```bash
# Copy and configure .env file
cp .env.example .env
# Edit .env with your Zou backend URLs

# Build and start production container (automatically loads .env)
docker compose up --build kitsu
```

## Environment Variables

Configuration is done via environment variables. Create a `.env` file from the example:

```bash
cp .env.example .env
# Edit .env with your Zou backend URLs
```

| Variable | Description | Default |
|----------|-------------|---------|
| `KITSU_PORT` | Port to expose production server on | `8080` |
| `KITSU_DEV_PORT` | Port to expose dev server on | `8081` |
| `KITSU_IMAGE` | Custom container image (pulls from registry) | `kitsu:latest` |
| `KITSU_DOCKERFILE` | Dockerfile to use for building | `Dockerfile` |
| `KITSU_API_TARGET` | Zou API endpoint | `http://localhost:5000` |
| `KITSU_EVENT_TARGET` | Zou WebSocket endpoint | `http://localhost:5001` |

**Usage:**
- **Local development**: Set in `.env` file or export as shell variables
- **Docker Compose**: Automatically loads from `.env` file
- **Vite dev server**: Reads from `vite.config.js` proxy config (uses env vars)
- **Nginx (production)**: Injected at container startup via `docker-entrypoint.sh`

**Example `.env` file:**
```bash
KITSU_API_TARGET=http://your-zou-host:5000
KITSU_EVENT_TARGET=http://your-zou-host:5001
```

## Docker Services

### `kitsu-dev`
Development server with hot module replacement. Mounts source code as volume for live updates.

**Usage:**
```bash
docker compose up kitsu-dev
```

**Features:**
- Hot module replacement (HMR)
- Source code mounted as volume
- Connects to Zou backend via environment variables

### `kitsu`
Production build served via nginx. Static files are built into the image.

**Usage:**
```bash
docker compose up --build kitsu
```

**Features:**
- Optimized production build
- Nginx with gzip compression
- API and WebSocket proxying to Zou backend

## Architecture

- **Frontend**: Vue 3 + Vuex + Vue Router
- **Build Tool**: Vite
- **Styling**: Bulma CSS framework
- **API Communication**: Superagent (HTTP) + Socket.IO (WebSocket)

The frontend communicates with Zou backend via:
- REST API at `/api/*` → proxied to Zou API
- WebSocket at `/socket.io/*` → proxied to Zou Events

### Proxy Configuration

**Development (Vite):**
- Configured in `vite.config.js`
- Uses Vite's built-in proxy
- Respects `KITSU_API_TARGET` and `KITSU_EVENT_TARGET` env vars

**Production (Nginx):**
- Uses `nginx.conf.template` with environment variable substitution
- Entrypoint script (`docker-entrypoint.sh`) injects env vars at runtime
- Supports dynamic backend URLs without rebuilding image

## Building Custom Images

To build your own Kitsu image with customizations:

```bash
# Build production image
docker build -t your-registry/kitsu:latest .

# Build development image
docker build -f Dockerfile.dev -t your-registry/kitsu:dev .
```

**Image includes:**
- Production: Built Vue app + Nginx with proxy configuration
- Development: Node.js environment with Vite dev server

## Multi-Platform Builds

For deploying to different architectures (e.g., building on Mac M-series for Linux AMD64 servers):

### Setup buildx

```bash
# Create multi-platform builder
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect --bootstrap
```

### Option 1: Build locally, then package (Recommended)

This is faster as it avoids running npm/vite inside Docker emulation:

```bash
# 1. Build the app locally
npm run build

# 2. Build and push multi-platform image using Dockerfile.prod
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f Dockerfile.prod \
  -t your-registry/kitsu:latest \
  --push \
  .
```

**Note:** Requires `Dockerfile.prod` (see below) and a pre-built `dist/` folder.

### Option 2: Full build in Docker

```bash
# Build and push for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t your-registry/kitsu:latest \
  --push \
  .
```

**Note:** This runs the full npm build inside Docker for each platform, which can be slow.

### Dockerfile.prod (for pre-built assets)

Create `Dockerfile.prod` for faster multi-platform builds:

```dockerfile
FROM nginx:alpine

RUN apk add --no-cache gettext

COPY dist /usr/share/nginx/html
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

### GCP Artifact Registry Example

```bash
# Authenticate
gcloud auth configure-docker us-central1-docker.pkg.dev

# Create repository (if needed)
gcloud artifacts repositories create kitsu-repo \
  --repository-format=docker \
  --location=us-central1

# Build locally
npm run build

# Build and push multi-platform
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f Dockerfile.prod \
  -t us-central1-docker.pkg.dev/YOUR_PROJECT/kitsu-repo/kitsu:latest \
  --push \
  .
```

### Pull and Run on Target Platform

```bash
# On your server (automatically pulls correct architecture)
docker pull us-central1-docker.pkg.dev/YOUR_PROJECT/kitsu-repo/kitsu:latest
docker compose up -d
```

## Development

```bash
# Install dependencies
npm install

# Run linter
npm run lint

# Fix linting issues
npm run lint:fix

# Format code
npm run format

# Run tests
npm test
```

## Deployment

### Cloud Run (GCP)

```bash
# Build and push to Artifact Registry
gcloud builds submit --tag gcr.io/YOUR_PROJECT/kitsu:latest

# Deploy to Cloud Run
gcloud run deploy kitsu \
  --image gcr.io/YOUR_PROJECT/kitsu:latest \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "KITSU_API_TARGET=http://your-zou-host:5000,KITSU_EVENT_TARGET=http://your-zou-host:5001" \
  --port 80
```

### Docker Compose (Standalone)

```bash
# Copy example .env file
cp .env.example .env

# Edit .env with your Zou backend URLs
# KITSU_API_TARGET=http://your-zou-host:5000
# KITSU_EVENT_TARGET=http://your-zou-host:5001

# Start production service
docker compose up -d kitsu
```

### Kubernetes

Example deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kitsu
spec:
  replicas: 2
  selector:
    matchLabels:
      app: kitsu
  template:
    metadata:
      labels:
        app: kitsu
    spec:
      containers:
      - name: kitsu
        image: your-registry/kitsu:latest
        ports:
        - containerPort: 80
        env:
        - name: KITSU_API_TARGET
          value: "http://zou-service:5000"
        - name: KITSU_EVENT_TARGET
          value: "http://zou-events-service:5001"
```

## Troubleshooting

### Cannot connect to Zou backend

**Issue:** Frontend shows "server down" or connection errors.

**Solutions:**
1. Verify Zou is running and accessible:
   ```bash
   curl http://your-zou-host:5000/api/status
   ```

2. Check environment variables are set correctly:
   ```bash
   echo $KITSU_API_TARGET
   echo $KITSU_EVENT_TARGET
   ```

3. For Docker, ensure `host.docker.internal` resolves (Linux may need `--add-host`):
   ```bash
   docker compose up --add-host=host.docker.internal:host-gateway
   ```

4. Check firewall rules allow connections between containers/hosts

### CORS errors

If Zou backend is on a different domain, ensure Zou's CORS settings allow your Kitsu frontend domain.

### WebSocket connection fails

- Verify `KITSU_EVENT_TARGET` points to Zou's WebSocket port (default: 5001)
- Check that WebSocket upgrade headers are properly configured in nginx
- Ensure Zou events service is running

## Documentation

For further information about features and installation, please refer to the
[documentation website](https://kitsu.cg-wire.com/).

## Contributing

There are many ways to contribute to Kitsu, from simple tasks to most complex ones. We created a
[contributing guide](https://github.com/cgwire/kitsu/blob/main/CONTRIBUTING.md) explaining everything.
You will find all the information you are looking for!

## About authors

Kitsu is written by CGWire, a company based in France. We help animation and VFX studios to collaborate better through efficient tooling.

More than 300 studios around the world use Kitsu for their projects.

Visit [cg-wire.com](https://cg-wire.com) for more information.

[![CGWire Logo](https://zou.cg-wire.com/cgwire.png)](https://cg-wire.com)
