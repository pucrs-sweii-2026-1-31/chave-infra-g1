#!/bin/sh
set -eu

mode="${1:-endpoints}"

fail() {
  echo "[verify] ERROR: $*" >&2
  exit 1
}

info() {
  echo "[verify] $*"
}

env_value() {
  key="$1"
  default_value="$2"
  current_value="$(eval "printf '%s' \"\${$key:-}\"")"

  if [ -n "$current_value" ]; then
    printf '%s\n' "$current_value"
    return
  fi

  if [ -f .env ]; then
    file_value="$(grep -E "^${key}=" .env | tail -n 1 | cut -d= -f2- || true)"
    if [ -n "$file_value" ]; then
      printf '%s\n' "$file_value"
      return
    fi
  fi

  printf '%s\n' "$default_value"
}

require_service() {
  service="$1"
  printf '%s\n' "$services" | grep -qx "$service" || fail "Compose service '$service' is missing"
}

check_url() {
  label="$1"
  url="$2"
  info "Checking $label: $url"
  curl -fsS "$url" >/dev/null || fail "$label did not respond at $url"
}

case "$mode" in
  topology|endpoints) ;;
  *)
    fail "Unknown mode '$mode'. Use 'topology' or 'endpoints'."
    ;;
esac

command -v docker >/dev/null 2>&1 || fail "docker is required"

services="$(docker compose config --services)"

require_service postgres
require_service ministack
require_service chave-ms-auth
require_service chave-mfe-auth
require_service chave-shell

profile_services="$(docker compose --profile provision config --services)"
printf '%s\n' "$profile_services" | grep -qx infra-provisioner || fail "Optional infra-provisioner profile is missing"

info "Compose topology is valid."

if [ "$mode" = "topology" ]; then
  exit 0
fi

ms_auth_port="$(env_value MS_AUTH_PORT 3001)"
mfe_auth_port="$(env_value MFE_AUTH_PORT 4001)"
shell_port="$(env_value SHELL_PORT 3000)"
ministack_port="$(env_value MINISTACK_PORT 4566)"

auth_api_url="$(env_value AUTH_API_URL "")"
if [ -z "$auth_api_url" ]; then
  auth_api_url="$(env_value AUTH_API_PUBLIC_URL "http://localhost:${ms_auth_port}")"
fi

mfe_auth_url="$(env_value MFE_AUTH_URL "http://localhost:${mfe_auth_port}")"
shell_url="$(env_value SHELL_URL "http://localhost:${shell_port}")"
ministack_url="$(env_value MINISTACK_URL "http://localhost:${ministack_port}")"

check_url "Backend health" "${auth_api_url}/health"
check_url "Swagger" "${auth_api_url}/docs"
check_url "Auth MFE remote entry" "${mfe_auth_url}/assets/remoteEntry.js"
check_url "Shell" "$shell_url"
check_url "Ministack health" "${ministack_url}/_localstack/health"

info "Local stack endpoints responded successfully."
