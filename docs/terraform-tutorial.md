# Terraform Tutorial

This document explains how to run `chave-infra` with the project's local
Terraform setup.

In this repository, Terraform is optional. Docker Compose starts the application
containers, while Terraform provisions AWS-like resources inside Ministack.

## What Terraform Does

Terraform creates local resources in Ministack:

- S3 bucket for artifacts;
- bucket versioning;
- API Gateway REST API;
- `/auth` route;
- `/auth/{proxy+}` route;
- HTTP proxy integration pointing to `chave-ms-auth:3001`;
- `v1` stage.

It does not create PostgreSQL. The database runs as a Docker Compose container.

It also does not start the backend, the microfrontend, or the shell. Those
services are managed by Compose.

## Prerequisites

You need:

- Docker 24+ with Docker Compose v2;
- `make`;
- the application repositories in the same parent directory.

Expected structure:

```text
project/
|-- chave-infra-g1/
|-- chave-ms-auth/
|-- chave-mfe-auth/
`-- chave-shell/
```

You do not need to install Terraform on your machine. The project uses the
`hashicorp/terraform:1.8` image through Docker Compose.

## Step 1: Create The `.env` File

Enter the infra repository:

```bash
cd chave-infra-g1
```

Create `.env` from the example:

```bash
cp .env.example .env
```

If you run `make setup` without `.env`, the Makefile also creates this file
automatically.

## Step 2: Start The Main Stack

Run:

```bash
make setup
```

This command starts the main services:

- `postgres`;
- `ministack`;
- `chave-ms-auth`;
- `chave-mfe-auth`;
- `chave-shell`.

In this project, `make setup` does not run Terraform automatically.

## Step 3: Verify The Stack

After the containers are running, run:

```bash
make verify
```

This command checks:

- backend: `http://localhost:3001/health`;
- Swagger: `http://localhost:3001/docs`;
- auth MFE remote entry: `http://localhost:4001/assets/remoteEntry.js`;
- shell: `http://localhost:3000`;
- Ministack: `http://localhost:4566/_localstack/health`.

## Step 4: Initialize Terraform

Run:

```bash
make tf-init
```

This command:

- makes sure `ministack` is running;
- runs `terraform init` inside the `infra-provisioner` container;
- downloads the AWS provider used by Terraform.

## Step 5: Review The Plan

Before applying, check what will be created:

```bash
make tf-plan
```

On a clean run, the plan should show the S3 and API Gateway resources to be
created. The expected summary looks like this:

```text
Plan: 11 to add, 0 to change, 0 to destroy.
```

## Step 6: Apply Terraform

To create the resources in Ministack:

```bash
make provision
```

This command runs:

```bash
docker compose --profile provision run --rm infra-provisioner
```

The `infra-provisioner` service executes:

```bash
terraform init && terraform apply -auto-approve
```

At the end, Terraform should print outputs like:

```text
artifact_bucket = "chave-artifacts-local"
gateway_url = "http://ministack:4566/restapis/<api-id>/v1/_user_request_"
```

## Step 7: Confirm State Convergence

After applying, run the plan again:

```bash
make tf-plan
```

When everything is synchronized, the expected result is:

```text
No changes. Your infrastructure matches the configuration.
```

## Step 8: Read Outputs Later

To print the outputs again:

```bash
docker compose --profile provision run --rm --entrypoint terraform infra-provisioner output
```

To read only the gateway URL:

```bash
docker compose --profile provision run --rm --entrypoint terraform infra-provisioner output -raw gateway_url
```

The output uses `ministack` because that is the internal Docker network URL. To
access it from the host, replace `ministack` with `localhost`.

Example:

```text
Internal: http://ministack:4566/restapis/<api-id>/v1/_user_request_
Host:     http://localhost:4566/restapis/<api-id>/v1/_user_request_
```

## Step 9: Test The API Gateway

After starting the application and applying Terraform, test a route through API
Gateway:

```bash
GATEWAY_URL="$(docker compose --profile provision run --rm --entrypoint terraform infra-provisioner output -raw gateway_url | tail -n 1 | sed 's|ministack|localhost|')"
curl -i "$GATEWAY_URL/auth/me"
```

A `401` or `403` response from the API can be expected, because `/auth/me`
usually requires authentication. The important distinction is:

- HTTP response from the API: the Gateway reached the backend;
- connection error: the backend or Ministack is not reachable;
- Gateway `404`: the route or stage was probably not provisioned as expected.

You can also test login:

```bash
curl -i \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@chave.local","password":"Admin123!"}' \
  "$GATEWAY_URL/auth/login"
```

## Use The Gateway In The Frontend

By default, the auth MFE calls the API directly:

```text
http://localhost:3001
```

If you want the frontend to use API Gateway, first apply Terraform and copy the
gateway URL using `localhost`:

```text
http://localhost:4566/restapis/<api-id>/v1/_user_request_
```

Then edit `.env`:

```env
AUTH_API_PUBLIC_URL=http://localhost:4566/restapis/<api-id>/v1/_user_request_
```

Rebuild/start the services again:

```bash
make up
```

## Useful Commands

```bash
# List active services
docker compose ps

# Follow stack logs
make logs

# Review Terraform plan
make tf-plan

# Apply Terraform
make provision

# Print Terraform outputs
docker compose --profile provision run --rm --entrypoint terraform infra-provisioner output

# Validate direct stack endpoints
make verify
```

## Cleanup

To remove the resources provisioned by Terraform:

```bash
docker compose --profile provision run --rm --entrypoint terraform infra-provisioner destroy -auto-approve
```

To stop the stack:

```bash
make down
```

To remove volumes and start the stack again:

```bash
make reset
```

Warning: `make reset` removes Docker volumes, including local Ministack and
PostgreSQL data. Since Terraform state is stored in `terraform/terraform.tfstate`,
manual volume removal can make the local state differ from what exists in
Ministack. If that happens, run `make provision` again to reconcile the
resources.

## Common Problems

### `make setup` Fails While Building The Apps

Confirm that the sibling repositories exist in the same parent directory:

```text
project/
|-- chave-infra-g1/
|-- chave-ms-auth/
|-- chave-mfe-auth/
`-- chave-shell/
```

### Port Already In Use

Edit `.env` and change the conflicting port:

```env
DB_PORT=55432
MS_AUTH_PORT=3101
MFE_AUTH_PORT=4101
SHELL_PORT=3100
```

Then run:

```bash
make reset
```

### Terraform Cannot Find Ministack

Check whether the container is healthy:

```bash
docker compose ps ministack
curl -i http://localhost:4566/_localstack/health
```

Then run again:

```bash
make provision
```

### Terraform Files Owned By `root`

Because Terraform runs inside a container, Git-ignored files under `terraform/`,
such as `.terraform/` and `terraform.tfstate`, can appear owned by `root`. This
does not affect normal usage of `make tf-plan` and `make provision`.
