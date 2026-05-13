# Note:
 - Este goal.md foi escrito em primeira mão pelo autor Gabriel Stefanello e posteriormente enviado ao ChatGPT para que ele aprimorasse o conteudo do documento, tornando mais acertivo e que satisfizesse os requisitos necessários para entregar o código correto.

# Goal Specification

## Purpose

This file defines the target state for the complete P1 authentication and authorization delivery.

## Product Goal

Build a production-style, scope-appropriate authentication and authorization foundation for a microservices and microfrontends architecture.

This is not the full domain system. It is the shared auth foundation that later services and frontends can reuse.

## Required Deliverables

The final delivery must include:

- Authentication and authorization microservice.
- Authentication microfrontend.
- Shell integration for the auth microfrontend.
- Local infrastructure with Docker Compose, PostgreSQL, and local AWS-compatible support.
- Swagger/OpenAPI backend documentation.
- UI manual for the authentication frontend.
- Architecture Decision Record.
- CI/CD workflows that run real checks and produce build/release artifacts.
- Unit and integration verification.
- AI usage evidence for the implementation process.

## Repository Layout

The system is delivered as multiple repositories/folders, matching the course boilerplate structure:

```text
chave-ms-auth   -> authentication and authorization microservice
chave-mfe-auth  -> authentication microfrontend
chave-shell     -> host shell application
chave-infra     -> local infrastructure and provisioning
grupo-1         -> product spec, delivery docs, audit, and AI evidence
```

The preferred delivery model is side-by-side repositories rather than a monorepo. This follows the course boilerplate workflow and keeps each deployable unit independent.

## Backend Target

The authentication service must provide:

- TypeScript backend using NestJS.
- PostgreSQL persistence through Prisma.
- REST API documented with Swagger/OpenAPI.
- User registration.
- User login.
- Access token issuance.
- Refresh token issuance.
- Refresh token rotation.
- Logout current session.
- Logout all sessions.
- Current authenticated user lookup.
- Forgot password flow.
- Reset password flow.
- Change password flow.
- Basic profile read/update.
- Role assignment support.
- Route protection based on roles.
- Token/session revocation.
- Token introspection for gateway-style validation.
- Health check endpoint.

The backend security model must include:

- Short-lived JWT access tokens.
- Long-lived refresh tokens delivered through httpOnly cookies.
- Refresh token persistence as hashes, never raw token storage.
- Persisted sessions.
- Refresh token reuse detection.
- Session revocation on logout, password reset, or detected reuse.
- Password hashing.
- Input validation.
- Safe, non-leaky error handling.

## Authorization Target

The authorization model is RBAC.

Required roles:

- `admin`
- `staff`
- `user`

Course-compatible roles also supported:

- `gestor`
- `participante`

Protected backend routes must support:

- authenticated-only access
- role-restricted access

## Frontend Target

The auth microfrontend must use:

- React.
- TypeScript.
- MUI.
- Vite.
- Module Federation-compatible build setup.

Required screens:

- Login.
- Register.
- Forgot password.
- Reset password.
- Change password.
- Profile.
- Logout action.

Required frontend behavior:

- Session-aware routing.
- Protected routes.
- API client with credentialed cookie support.
- Access token stored in memory.
- Refresh token handled by backend httpOnly cookie.
- Loading and error states.
- Form validation.
- Accessibility-conscious UI.

## Accessibility Target

The UI must be practical for older adult users:

- clear labels
- good contrast
- generous spacing
- large enough click targets
- keyboard navigation
- visible focus states
- useful validation messages
- simple flows
- low visual clutter

## Local Development Target

The local environment must provide:

- PostgreSQL in Docker.
- Auth backend container.
- Auth MFE container.
- Shell container.
- Ministack/local AWS-compatible container.
- Environment-variable driven configuration.
- One-command or near-one-command startup from `chave-infra`.

Default local URLs:

```text
Shell:     http://localhost:3000
Auth MFE:  http://localhost:4001
Auth API:  generated in chave-infra-g1/.env.generated through Ministack API Gateway
Swagger:   ${AUTH_API_PUBLIC_URL}/docs
Ministack: http://localhost:4566
```

## CI/CD Target

Each application repository must have realistic GitHub Actions workflows.

Backend CI must run:

- dependency installation
- Prisma generation
- lint
- typecheck
- database migration against test PostgreSQL
- unit tests
- integration tests
- build
- Docker build
- artifact upload
- tag-based release

Frontend CI must run:

- dependency installation
- lint where applicable
- typecheck where applicable
- tests where applicable
- build
- Docker build
- artifact upload
- tag-based release

## Documentation Target

The delivery must include:

- ADR
- local setup guide
- backend README
- frontend README
- shell README
- infra README
- UI manual
- completion audit
- AI usage log
- raw or raw-style AI trace

## Testing Target

Backend tests must cover meaningful auth flows, including:

- registration
- login
- current user
- refresh rotation
- logout
- password reset flow
- admin-only access
- refresh token reuse detection

Frontend tests must cover:

- form rendering and validation
- login behavior
- protected route behavior
- profile behavior
- forgot/reset password behavior

## Non-Goals

The P1 delivery must not implement:

- full OAuth2 provider
- OpenID Connect discovery
- social login
- real external email provider
- full multi-tenant architecture
- full event-driven auth workflows
- Redis token blacklists
- unnecessary cloud complexity

## Acceptance Criteria

The system is ready when:

- `chave-infra` starts the full stack with Docker Compose.
- Shell loads the auth MFE.
- Auth MFE calls the auth backend successfully.
- Backend persists users, roles, sessions, refresh tokens, and reset tokens in PostgreSQL.
- Swagger is available.
- Unit/integration/frontend checks pass.
- CI workflows are present and realistic.
- Documentation and AI evidence exist in `grupo-1`.
