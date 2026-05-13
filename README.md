# chave-infra

Local infrastructure and orchestration for the Chave P1 authentication stack.

This repository starts the shared local services and the three application containers side by side:

- `postgres`
- `ministack`
- `chave-ms-auth`
- `chave-mfe-auth`
- `chave-shell`

Terraform provisioning is available as an optional profile for local AWS-compatible resources.
It is optional because the main local stack is fully orchestrated by Docker Compose: PostgreSQL,
Ministack, the auth backend, the auth MFE, and the shell can run and communicate directly without
Terraform. When the provisioning profile is not enabled, no other IaC tool replaces Terraform; the
application uses Compose networking, exposed local ports, and environment variables instead.
Terraform only creates extra local Ministack resources, such as the artifact bucket and API Gateway
proxy routes, for demonstration and future AWS-like integrations.

## Prerequisites

- Docker 24+ with Docker Compose v2
- `make`
- `curl` for endpoint verification

The application repositories must be checked out next to this repository:

```text
project/
├── chave-infra/
├── chave-ms-auth/
├── chave-mfe-auth/
└── chave-shell/
```

## Environment Setup

Create a local `.env` from the example:

```bash
cp .env.example .env
```

`make setup` also copies `.env.example` to `.env` when `.env` is missing.

Important values:

| Variable | Purpose | Default |
|---|---|---|
| `SHELL_PORT` | Host port for the shell app | `3000` |
| `MS_AUTH_PORT` | Host port for the auth API | `3001` |
| `MFE_AUTH_PORT` | Host port for the auth MFE | `4001` |
| `DB_PORT` | Host port for PostgreSQL | `5432` |
| `MINISTACK_PORT` | Host port for Ministack | `4566` |
| `DB_NAME`, `DB_USER`, `DB_PASSWORD` | PostgreSQL credentials | `chave_auth`, `chave`, `chave_secret` |
| `JWT_SECRET` | Local JWT signing secret | `local-development-jwt-secret-change-me-32-chars` |
| `JWT_ACCESS_TTL`, `JWT_REFRESH_TTL`, `PASSWORD_RESET_TOKEN_TTL` | Access, refresh, and password-reset token lifetimes | `15m`, `7d`, `30m` |
| `REFRESH_COOKIE_*` | Refresh-token cookie behavior | see `.env.example` |
| `SEED_ADMIN_*` | Seed admin account used by the backend | see `.env.example` |
| `AWS_*`, `MINISTACK_*` | Local AWS-compatible configuration | see `.env.example` |

When using alternate host ports on localhost, changing the `*_PORT` variables is enough because Compose derives the browser-facing URLs from those ports:

```env
MS_AUTH_PORT=3101
MFE_AUTH_PORT=4101
SHELL_PORT=3100
```

If you use a non-`localhost` hostname or custom path, uncomment and adjust the browser-facing URL overrides in `.env`.

## Startup

Start the full local stack with build:

```bash
make setup
```

Equivalent direct command:

```bash
docker compose up -d --build
```

Default URLs:

| Service | URL |
|---|---|
| Shell | http://localhost:3000 |
| Auth MFE | http://localhost:4001 |
| Auth API | http://localhost:3001 |
| Swagger | http://localhost:3001/docs |
| PostgreSQL | `localhost:5432` |
| Ministack | http://localhost:4566 |

Service roles:

| Service | Role |
|---|---|
| Shell | Frontend host that loads and composes the microfrontends |
| Auth MFE | Authentication UI exposed as a microfrontend |
| Auth API | Backend authentication service and auth business rules |
| Swagger | Interactive API documentation for the auth backend |
| PostgreSQL | Local relational database used by the auth backend |
| Ministack | Local AWS-compatible emulator for S3/API Gateway demos |

## Common Commands

| Command | Description |
|---|---|
| `make setup` | Copy `.env` if needed, check sibling app Dockerfiles/lockfiles, and start the full stack with image builds |
| `make up` | Start or rebuild the stack |
| `make down` | Stop and remove containers |
| `make logs` | Follow all container logs |
| `make reset` | Stop the stack, remove volumes, rebuild, and start again |
| `make ps` | Show Compose service state |
| `make config` | Render the resolved Compose configuration |
| `make verify` | Check the expected local HTTP endpoints |
| `make verify-topology` | Check Compose service/profile topology without requiring running endpoints |
| `make provision` | Run optional Terraform provisioning against Ministack |
| `make tf-init` | Run `terraform init` in the Terraform container |
| `make tf-plan` | Run `terraform plan` in the Terraform container |
| `make tf-apply` | Alias for `make provision` |

## Service Wiring

`postgres` is the application database. The backend receives both `DATABASE_URL` and the legacy `DB_*` variables, with `DB_HOST=postgres` and internal port `5432`.

`ministack` provides local AWS-compatible endpoints for P1 demos and future integrations. The backend receives internal endpoint variables pointing to `http://ministack:4566`.

`chave-ms-auth` waits for healthy PostgreSQL and Ministack services. On startup it runs Prisma migrations and seed data when a `prisma/schema.prisma` file exists, then starts the backend.

`chave-mfe-auth` builds with `VITE_AUTH_API_URL` and `VITE_MS_AUTH_URL` pointing to the host-accessible auth API URL.

`chave-shell` builds with the auth MFE remote entry URL.

## Optional Ministack Provisioning

Terraform is intentionally minimal. It provisions:

- an S3-style artifact bucket
- an API Gateway REST API with `/auth` and `/auth/{proxy+}` proxy routes to the auth service

Run it after the stack is available:

```bash
make provision
```

The Terraform image runs inside Docker Compose, so a local Terraform binary is not required.

## Verification

After `make setup`, verify the required endpoints:

```bash
make verify
```

The checks cover:

- backend health: `http://localhost:3001/health`
- Swagger: `http://localhost:3001/docs`
- auth MFE remote entry: `http://localhost:4001/assets/remoteEntry.js`
- shell: `http://localhost:3000`
- Ministack health: `http://localhost:4566/_localstack/health`

To validate only the Compose service and profile definitions, run:

```bash
make verify-topology
```

The current prompt-to-artifact status is tracked in [docs/completion-audit.md](docs/completion-audit.md).

If a machine already uses one of the default ports, change the matching `*_PORT` values in `.env`, adjust any enabled URL overrides, then run `make reset`.

For a one-off run without editing `.env`, pass overrides as make variables:

```bash
make DB_PORT=55432 setup
```
