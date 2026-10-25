#!/usr/bin/env bash
# One-time setup of the VPS for the deploy workflow. Run as root on the server,
# next to the public deploy key:
#
#   sudo bash setup-server.sh /path/to/bida-deploy.pub
#
# Adds to the stack in /opt/bida (compose.yml, caddy/Caddyfile, .env) without
# editing compose.yml: the API goes into compose.override.yml, the Caddy blocks
# are appended to the Caddyfile. Safe to run again. See docs/DEPLOYMENT.md.
set -euo pipefail

STACK=/opt/bida
KEY_FILE=${1:?usage: setup-server.sh <public key file>}

[ "$(id -u)" -eq 0 ] || { echo "run as root (sudo)"; exit 1; }
[ -f "$STACK/compose.yml" ] || { echo "$STACK/compose.yml not found"; exit 1; }
grep -q '^ssh-' "$KEY_FILE" || { echo "$KEY_FILE is not a public key"; exit 1; }

command -v rsync >/dev/null || dnf install -y rsync

# --- deploy user: may use Docker, nothing else ------------------------------
id deploy >/dev/null 2>&1 || useradd --create-home --shell /bin/bash deploy
usermod -aG docker deploy
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
touch /home/deploy/.ssh/authorized_keys
grep -qxF "$(cat "$KEY_FILE")" /home/deploy/.ssh/authorized_keys ||
  cat "$KEY_FILE" >> /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys

# --- static files the workflow uploads --------------------------------------
install -d -m 755 -o deploy -g deploy "$STACK/app" "$STACK/docs"

# --- the stack's secrets are readable by root and the docker group only -----
chgrp docker "$STACK/.env"
chmod 640 "$STACK/.env"

# --- API settings: the connection string needs the password URL-encoded -----
set -a
. "$STACK/.env"
set +a
DATABASE_URL=$(python3 - <<PY
import os, urllib.parse as u
q = lambda v: u.quote(v, safe="")
print(f"postgres://{q(os.environ['DB_USER'])}:{q(os.environ['DB_PASSWORD'])}@db:5432/{q(os.environ['DB_NAME'])}")
PY
)
umask 027
cat > "$STACK/backend.env" <<ENV
PORT=3000
DATABASE_URL=$DATABASE_URL
CORS_ORIGINS=https://app.bida.maknet.com.pl,https://docs.bida.maknet.com.pl
ENV
chgrp docker "$STACK/backend.env"
chmod 640 "$STACK/backend.env"

# --- compose override: the API, and the static files for Caddy --------------
# :z relabels the directories for SELinux, otherwise Caddy cannot read them.
cat > "$STACK/compose.override.yml" <<'YML'
services:
  backend:
    image: ghcr.io/geraldserafin/bida-api:${TAG:-latest}
    restart: unless-stopped
    env_file: backend.env
    depends_on:
      db:
        condition: service_healthy
    networks:
      - bida_network
  proxy:
    volumes:
      - ./app:/srv/app:ro,z
      - ./docs:/srv/docs:ro,z
YML

# --- Caddy: the API block already exists, add the two static sites ----------
CADDYFILE=$STACK/caddy/Caddyfile
if ! grep -q 'app.bida.maknet.com.pl' "$CADDYFILE"; then
  cp "$CADDYFILE" "$CADDYFILE.bak-$(date +%Y%m%d%H%M%S)"
  cat >> "$CADDYFILE" <<'CADDY'

app.bida.maknet.com.pl {
	root * /srv/app
	try_files {path} /index.html
	file_server
}

docs.bida.maknet.com.pl {
	root * /srv/docs
	file_server
}
CADDY
fi

cd "$STACK"
docker compose config --quiet
# not `compose run`: the proxy has a fixed IP that the running one already holds
docker run --rm --network none -v "$CADDYFILE:/etc/caddy/Caddyfile:ro,z" caddy:latest \
  caddy validate --config /etc/caddy/Caddyfile
# recreates the proxy because of the new volumes (a few seconds without HTTPS)
docker compose up -d proxy
echo "done: deploy user, directories, backend.env, compose.override.yml, Caddy"
