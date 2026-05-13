# chave-infra Completion Audit

Date: 2026-05-12

## Objective

Transform `chave-infra` into the local orchestration and provisioning repository for the P1 authentication stack described by `goal.md` and `chave-infra.md`.

Concrete success criteria:

- Docker Compose defines and wires PostgreSQL, Ministack, auth backend, auth MFE, shell, and Terraform gateway provisioning.
- Configuration is environment-variable driven, including alternate host ports.
- The backend receives database, JWT/token, CORS, reset URL, seed admin, and Ministack variables.
- Frontend containers receive the generated Ministack API Gateway URL and remote-entry URLs at build/runtime.
- Terraform remains minimal and provisions local AWS-compatible P1 resources.
- Makefile provides setup, lifecycle, log, reset, provisioning, and verification targets.
- README explains setup, URLs, alternate ports, Ministack, and gateway provisioning.
- Acceptance commands can verify the stack once sibling app repositories provide the required containers and endpoints.

## Prompt-To-Artifact Checklist

| Requirement | Evidence | Status |
|---|---|---|
| Read overall system goal from `goal.md` | `goal.md` exists in this repository and was reviewed before implementation. | Done |
| Read service goal from `chave-infra.md` | `chave-infra.md` exists in this repository and drives this checklist. | Done |
| Compose defines `postgres` | `docker-compose.yml` service `postgres`; `docker compose config --services` includes `postgres`. | Done |
| Compose defines `ministack` | `docker-compose.yml` service `ministack`; `docker compose config --services` includes `ministack`. | Done |
| Compose defines `chave-ms-auth` | `docker-compose.yml` service `chave-ms-auth`; `docker compose config --services` includes it. | Done |
| Compose defines `chave-mfe-auth` | `docker-compose.yml` service `chave-mfe-auth`; `docker compose config --services` includes it. | Done |
| Compose defines `chave-shell` | `docker-compose.yml` service `chave-shell`; `docker compose config --services` includes it. | Done |
| `infra-provisioner` profile exists | `docker-compose.yml` service `infra-provisioner` has `provision` and `infra-provisioner` profiles; `docker compose --profile provision config --services` includes it. | Done |
| Backend waits for PostgreSQL and Ministack health | `chave-ms-auth.depends_on` uses `service_healthy` for `postgres` and `ministack`. | Done |
| MFE waits for backend start | `chave-mfe-auth.depends_on` waits for `chave-ms-auth` with `service_started`. | Done |
| Shell waits for MFE start | `chave-shell.depends_on` waits for `chave-mfe-auth` start. | Done |
| Configurable `DB_PORT` | `postgres.ports` uses `${DB_PORT:-5432}:5432`; alternate render checked with `DB_PORT=55432`. | Done |
| Configurable `MS_AUTH_PORT` | `chave-ms-auth.ports` uses `${MS_AUTH_PORT:-3001}:3001`; alternate render checked with `MS_AUTH_PORT=3101`. | Done |
| Configurable `MFE_AUTH_PORT` | `chave-mfe-auth.ports` uses `${MFE_AUTH_PORT:-4001}:4001`; alternate render checked with `MFE_AUTH_PORT=4101`. | Done |
| Configurable `SHELL_PORT` | `chave-shell.ports` uses `${SHELL_PORT:-3000}:3000`; alternate render checked with `SHELL_PORT=3100`. | Done |
| `.env.example` documents service ports | `.env.example` includes `SHELL_PORT`, `MS_AUTH_PORT`, `MFE_AUTH_PORT`, `DB_PORT`, and `MINISTACK_PORT`. | Done |
| `.env.example` documents database settings | `.env.example` includes `DB_NAME`, `DB_USER`, and `DB_PASSWORD`. | Done |
| `.env.example` documents JWT/token settings | `.env.example` includes `JWT_SECRET`, `JWT_ACCESS_TTL`, `JWT_REFRESH_TTL`, and `PASSWORD_RESET_TOKEN_TTL`. | Done |
| `.env.example` documents refresh cookie settings | `.env.example` includes `REFRESH_COOKIE_*` variables. | Done |
| `.env.example` documents seed admin credentials | `.env.example` includes `SEED_ADMIN_EMAIL`, `SEED_ADMIN_PASSWORD`, and `SEED_ADMIN_NAME`. | Done |
| `.env.example` documents AWS/Ministack variables | `.env.example` includes `MINISTACK_*`, `AWS_*`, and Terraform bucket variables. | Done |
| Default URLs are documented | `README.md` lists Shell, Auth MFE, Auth API, Swagger, PostgreSQL, and Ministack URLs. | Done |
| Alternate port usage works | `env MS_AUTH_PORT=3101 MFE_AUTH_PORT=4101 SHELL_PORT=3100 DB_PORT=55432 docker compose config --quiet` passed. | Done |
| Backend receives `DATABASE_URL` to Compose PostgreSQL | `docker-compose.yml` sets `DATABASE_URL` pointing at `postgres:5432`. | Done |
| Backend receives JWT/token configuration | `docker-compose.yml` passes JWT/access/refresh/password-reset TTL variables. | Done |
| Backend receives frontend CORS origins | `docker-compose.yml` passes `FRONTEND_CORS_ORIGINS`, `FRONTEND_ORIGINS`, and `CORS_ORIGIN`. | Done |
| Backend receives reset password frontend URL | `docker-compose.yml` passes reset URL aliases. | Done |
| Backend receives seed admin credentials | `docker-compose.yml` passes `SEED_ADMIN_*`. | Done |
| Backend receives Ministack endpoint variables | `docker-compose.yml` passes `AWS_ENDPOINT`, `AWS_ENDPOINT_URL`, and `LOCALSTACK_ENDPOINT` pointing to `http://ministack:4566`. | Done |
| Backend runs migrations and seed before app start | `chave-ms-auth.command` runs Prisma migration and seed when `prisma/schema.prisma` exists before starting the app. | Done |
| Auth MFE builds with `VITE_AUTH_API_URL` | `chave-mfe-auth.build.args` includes `VITE_AUTH_API_URL` derived from generated `AUTH_API_PUBLIC_URL`. | Done |
| Shell builds with `MFE_AUTH_URL` | `chave-shell.build.args` includes `MFE_AUTH_URL` derived from the host-accessible remote entry URL. | Done |
| Ministack gateway is default auth route | `make setup` provisions a Ministack API Gateway and writes `AUTH_API_PUBLIC_URL` to `.env.generated` before building the auth MFE. | Done |
| Terraform provisions artifact bucket | `terraform/main.tf` defines `aws_s3_bucket.artifacts` and versioning. | Done |
| Terraform provisions API Gateway proxy resources | `terraform/main.tf` defines root proxy and `/auth` proxy resources. | Done |
| Terraform remains minimal | Terraform config is limited to S3, API Gateway, and provider setup; no extra cloud complexity. | Done |
| Makefile provides `setup` | `Makefile` target `setup` copies `.env` if needed, checks sibling Dockerfiles/lockfiles, and starts Compose with build. | Done |
| Makefile provides `up`, `down`, `logs`, `reset`, `provision` | `Makefile` contains all required lifecycle targets. | Done |
| Terraform helper targets exist | `Makefile` contains `tf-init`, `tf-plan`, and `tf-apply`. | Done |
| README explains prerequisites and `.env` setup | `README.md` has prerequisites and environment setup sections. | Done |
| README explains startup and stop/reset commands | `README.md` common commands section covers startup, stop, logs, reset, and provisioning. | Done |
| README explains service URLs | `README.md` default URL table covers required services. | Done |
| README explains alternate port usage | `README.md` documents changing `*_PORT` values and optional URL overrides. | Done |
| README explains Ministack role and gateway provisioning | `README.md` service wiring and Ministack provisioning sections cover this. | Done |
| Verification target exists | `scripts/verify-stack.sh`, `make verify`, and `make verify-topology` exist. | Done |
| Docker Compose builds backend, MFE, and shell images | `make setup` built all three application images successfully. | Done |
| `make setup` starts local stack | `make setup` completed with the local `.env` using `DB_PORT=55432` because host port `5432` is already occupied on this machine. | Done |
| PostgreSQL becomes healthy | `docker compose ps` and `make verify` confirmed PostgreSQL-backed services are running; Compose reported `chave-postgres` healthy. | Done |
| Ministack becomes healthy | `docker compose ps` and `make verify` confirmed `chave-ministack` healthy and `/_localstack/health` reachable. | Done |
| Backend health endpoint responds | `make verify` passed health through the generated `AUTH_API_PUBLIC_URL`. | Done |
| Swagger responds | `make verify` passed Swagger through the generated `AUTH_API_PUBLIC_URL`. | Done |
| MFE remote entry responds | `make verify` passed `http://localhost:4001/assets/remoteEntry.js`. | Done |
| Shell responds | `make verify` passed `http://localhost:3000`. | Done |

## Verification Evidence

Passing checks:

```bash
docker compose config --quiet
docker compose --profile provision config --services
docker compose --profile infra-provisioner config --services
env MS_AUTH_PORT=3101 MFE_AUTH_PORT=4101 SHELL_PORT=3100 DB_PORT=55432 docker compose config --quiet
sh -n scripts/verify-stack.sh
make check-repos
make setup
make verify-topology
make verify
env MS_AUTH_PORT=3101 MFE_AUTH_PORT=4101 SHELL_PORT=3100 DB_PORT=55432 ./scripts/verify-stack.sh topology
docker run --rm -v "$PWD/terraform:/infra" -w /infra hashicorp/terraform:1.8 fmt -check
docker run --rm -v "$PWD/terraform:/infra" -w /infra hashicorp/terraform:1.8 validate
git diff --check -- .
```

No current infra validation failures remain. The active local `.env` uses `DB_PORT=55432` to avoid a host-level `5432` port conflict on this machine; the committed `.env.example` keeps the standard `5432` default.

## Completion Status

`chave-infra` is implemented as the orchestration/provisioning repository and has end-to-end local verification against the completed sibling repositories.

The full P1 stack starts with `make setup`, exposes the required endpoints, and passes `make verify`.
