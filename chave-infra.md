# chave-infra Specification

## Purpose

Transform `chave-infra` from the current infrastructure boilerplate into the local orchestration and provisioning repository for the complete P1 auth stack described in `goal.md`.

## Starting Point

The starting point is the existing infrastructure boilerplate.

What is done here is: 

- Infrastructure-focused repository.
- Docker Compose and Terraform scaffolding.
- Local AWS-compatible infrastructure expectation.
- No complete orchestration of the finished auth service, auth MFE, and shell as one verified local stack.

## Target State

The repository must provide a one-command or near-one-command local environment for:

- PostgreSQL
- Ministack
- auth microservice
- auth microfrontend
- shell frontend
- optional Terraform provisioning against Ministack

## Docker Compose Requirements

`docker-compose.yml` must define:

- `postgres`
- `ministack`
- `chave-ms-auth`
- `chave-mfe-auth`
- `chave-shell`
- optional `infra-provisioner` profile

The services must be wired with correct dependencies:

- backend waits for PostgreSQL and Ministack health
- MFE waits for backend start
- shell waits for MFE start

The stack must support configurable host ports:

- `DB_PORT`
- `MS_AUTH_PORT`
- `MFE_AUTH_PORT`
- `SHELL_PORT`

## Environment Requirements

`.env.example` must document:

- service ports
- database user/password/name
- JWT secret
- token TTLs
- refresh cookie settings
- seed admin credentials
- AWS/Ministack variables

Default URLs:

```text
Shell:     http://localhost:3000
Auth MFE:  http://localhost:4001
Auth API:  http://localhost:3001
Swagger:   http://localhost:3001/docs
Ministack: http://localhost:4566
```

The stack must also work with alternate ports for machines that already have PostgreSQL or frontend ports occupied.

## Backend Runtime Requirements

The Compose service for `chave-ms-auth` must pass:

- `DATABASE_URL` pointing to Compose PostgreSQL
- JWT/token configuration
- frontend CORS origins
- reset password frontend URL
- seed admin credentials
- Ministack endpoint variables

The backend container must run migrations and seed data before starting the app.

## Frontend Runtime Requirements

The Compose service for `chave-mfe-auth` must build with:

- `VITE_AUTH_API_URL` pointing to the host-accessible auth API URL

The Compose service for `chave-shell` must build with:

- `MFE_AUTH_URL` pointing to the host-accessible MFE `remoteEntry.js`

## Ministack Requirements

Ministack must be included because the course architecture expects local AWS-like support.

Currently, auth logic does not need deep AWS integration. Ministack should remain minimally coupled but available for:

- S3-style artifact/resource experiments
- API Gateway-style future integration
- Terraform provisioning demonstration

## Terraform Requirements

Terraform must remain practical and minimal.

It should provision local AWS-compatible resources only where useful for P1, such as:

- artifact bucket
- API Gateway proxy resources for auth-style routing

It must not introduce unnecessary cloud complexity.

## Makefile Requirements

The Makefile must provide:

- `setup`
- `up`
- `down`
- `logs`
- `reset`
- `provision`
- Terraform helper targets where useful

`setup` must copy or require `.env` and then start the stack with build.

## Documentation Requirements

The infra README must explain:

- prerequisites
- `.env` setup
- startup commands
- stop/reset commands
- service URLs
- alternate port usage
- role of Ministack
- optional provisioning

## Acceptance Criteria

This repository is ready when:

- `make setup` starts the local stack.
- Docker Compose builds the backend, MFE, and shell images.
- PostgreSQL becomes healthy.
- Ministack becomes healthy.
- Backend health endpoint responds.
- Swagger responds.
- MFE remote entry responds.
- Shell responds.
- Optional alternate port configuration works.

