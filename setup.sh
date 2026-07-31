#!/usr/bin/env bash
#
# lochan-qapp setup — take a fresh clone to a running Lochan app.
#
#   git clone https://github.com/ssnukala/lochan-qapp.git my-app
#   cd my-app && ./setup.sh
#
# WHAT THIS SCRIPT DOES NOT DO: hand-roll configuration. Every compose file and
# Dockerfile is produced by the framework's own generator, which ships inside
# the Lochan backend image. `packages.json` is the only configuration file this
# repo commits; everything else is generated and gitignored, so the repo cannot
# drift from what the framework emits.
#
# Requirements: docker (with compose), openssl, git. No Python needed on the
# host — the generator runs inside the image.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app_name="$(basename "$here")"
image="${LOCHAN_IMAGE:-ghcr.io/ssnukala/lochan-backend-base:latest}"

step() { printf '\n==> %s\n' "$1"; }
die()  { printf '\nERROR: %s\n' "$1" >&2; exit 1; }

for tool in docker openssl; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool not found on PATH — it is required."
done

# ── 1. Fetch the framework image ────────────────────────────────────────────
#
# This is the first thing a stranger cannot currently do: the GHCR packages are
# not published, so an anonymous pull returns 403. FAIL LOUD here rather than
# continuing into a build that would fail more confusingly later.

step "Pulling the Lochan framework image ($image)"
if ! docker image inspect "$image" >/dev/null 2>&1; then
  if ! docker pull "$image"; then
    die "could not pull $image.

The Lochan framework images are not yet published for anonymous pull
(see: the publish pipeline, wave row W3). Until they are, you need either:

  * a local build of the image, tagged as:
      $image
  * or set LOCHAN_IMAGE=<an image you can pull> and re-run this script.

This script stops here deliberately rather than continuing into a build
that cannot succeed."
  fi
fi

# ── 2. Bootstrap secrets ────────────────────────────────────────────────────

step "Generating .env"
env_file="$here/.env"
example="$here/.env.example"

if [ -f "$env_file" ]; then
  echo "    .env exists; keeping it (delete it to regenerate secrets)"
else
  [ -f "$example" ] || die ".env.example not found at $example"

  # Fernet requires URL-safe base64; openssl emits standard base64, so the two
  # differing characters are translated. Verified against cryptography.fernet.
  encryption_key="$(openssl rand -base64 32 | tr '+/' '-_')"
  # Stripped of /+= because this value is interpolated into the DATABASE_URL
  # DSN, where those characters would corrupt the URL.
  postgres_password="$(openssl rand -base64 24 | tr -d '/+=')"
  jwt_secret="$(openssl rand -base64 32)"

  sed \
    -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${postgres_password}|" \
    -e "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=${encryption_key}|" \
    -e "s|^JWT_SECRET=.*|JWT_SECRET=${jwt_secret}|" \
    -e "s|__PROJECT_NAME__|${app_name}|g" \
    "$example" > "$env_file"
  chmod 600 "$env_file"

  # Assert what we report, rather than printing "done" and hoping.
  if grep -q "CHANGE_ME" "$env_file"; then
    grep -n "CHANGE_ME" "$env_file" >&2
    die "placeholders remain in .env after substitution"
  fi
  echo "    wrote .env (mode 600) with three generated secrets"
fi

# The framework's boot-time security gate refuses to start when CORS_ORIGINS
# points at localhost unless DEBUG is set. A local first run is exactly that.
grep -q '^DEBUG=' "$env_file" || \
  printf '\n# Local development: skips the production security gate.\nDEBUG=true\n' >> "$env_file"

# ── 3. Generate compose + Dockerfiles ───────────────────────────────────────

step "Generating compose files and Dockerfiles"
# NOTE: the --config path MUST include the app directory. The generator derives
# the app name from the config file's PARENT directory, so a bare
# `--config packages.json` yields an empty name and a malformed volume
# ("-pgdata"). Mounting at /apps/<app> and passing "<app>/packages.json" is the
# documented, correct invocation.
docker run --rm -v "$here:/apps/$app_name" -w /apps \
  --entrypoint python "$image" \
  /usr/local/lib/python3.13/site-packages/daksh/generators/generate-app-config.py \
  --config "$app_name/packages.json" >/dev/null

for f in compose.yml Dockerfile.backend build-app.sh; do
  [ -f "$here/$f" ] || die "the generator did not emit $f"
done
if grep -q -- "- -pgdata:" "$here/compose.yml"; then
  die "generated compose has a malformed volume name (the app name resolved empty)"
fi
echo "    generated compose.yml, Dockerfile.*, build-app.sh"

# ── 4. Build the package images ─────────────────────────────────────────────
#
# Each package in packages.json is built into a small image that the app image
# COPYs from (FROM <pkg>:latest AS pkg-<pkg>). Without this the app build fails
# with "pull access denied" on a package image that was never built.

step "Building package images"
for pkg_dir in "$here"/packages/*/; do
  [ -d "$pkg_dir" ] || continue
  pkg="$(basename "$pkg_dir")"
  [ -f "$pkg_dir/build.sh" ] || die "packages/$pkg has no build.sh — it cannot be built into an image."
  echo "    building $pkg"
  bash "$pkg_dir/build.sh" >/dev/null
  docker image inspect "$pkg:latest" >/dev/null 2>&1 || die "build.sh for $pkg did not produce $pkg:latest"
done

# ── 5. Build the app ────────────────────────────────────────────────────────

step "Building the application images"
bash "$here/build-app.sh" --prod

# ── 6. Up ───────────────────────────────────────────────────────────────────

step "Starting the stack"
cd "$here"
docker compose up -d

cat <<EOF

Done. The stack is starting — the backend autowires ~100 schemas on first boot,
so give it a minute before the health endpoint answers.

  docker compose ps          # container status
  docker compose logs -f backend
EOF
