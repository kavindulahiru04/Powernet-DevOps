#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="${WORKSPACE:-$(pwd)}"
cd "$ROOT"

echo "===== STAGE 1: CHECK NODE.JS ====="
node --version
npm --version

echo "===== STAGE 2: RUN AUTOMATED TESTS ====="
cd "$ROOT/app"

APP_LOG="$(mktemp)"
node app.js >"$APP_LOG" 2>&1 &
APP_PID=$!

cleanup_test_server() {
  kill "$APP_PID" >/dev/null 2>&1 || true
  wait "$APP_PID" >/dev/null 2>&1 || true
  rm -f "$APP_LOG"
}
trap cleanup_test_server EXIT

READY=0
for i in $(seq 1 20); do
  if curl --silent --fail http://127.0.0.1:3000 >/dev/null; then
    READY=1
    break
  fi
  sleep 1
done

if [ "$READY" -ne 1 ]; then
  echo "FAIL: Test application did not start."
  cat "$APP_LOG"
  exit 1
fi

npm test
cleanup_test_server
trap - EXIT
cd "$ROOT"

echo "===== STAGE 3: BUILD DOCKER IMAGE ====="
docker version --format 'Docker Engine server: {{.Server.Version}}'
docker build -t powernet-dashboard:1.0 ./app

echo "===== STAGE 4: DEPLOY LOCALLY WITH ANSIBLE ====="
ansible-playbook -i 'localhost,' ansible/deploy-dashboard.yml

echo "===== STAGE 5: VERIFY LOCAL DEPLOYMENT ====="
APP_IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' powernet-dashboard-container)"
test -n "$APP_IP"

LOCAL_HTML="$(mktemp)"
LOCAL_HTTP_CODE="$(curl --silent --show-error --output "$LOCAL_HTML" --write-out '%{http_code}' "http://${APP_IP}:3000")"
echo "LOCAL_HTTP_STATUS=${LOCAL_HTTP_CODE}"
test "$LOCAL_HTTP_CODE" = "200"
grep -q "Powernet IT Service Dashboard" "$LOCAL_HTML"
rm -f "$LOCAL_HTML"

echo "===== STAGE 6: DEPLOY TO AWS EC2 ====="
: "${AWS_SSH_KEY:?Missing SSH private-key credential binding}"
: "${AWS_SSH_USER:?Missing SSH username credential binding}"

AWS_HOST="3.111.47.164"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/known_hosts"
chmod 600 "$HOME/.ssh/known_hosts"

if ! ssh-keygen -F "$AWS_HOST" >/dev/null 2>&1; then
  ssh-keyscan -H "$AWS_HOST" >> "$HOME/.ssh/known_hosts" 2>/dev/null
fi

ssh -i "$AWS_SSH_KEY" \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=yes \
  -o ConnectTimeout=15 \
  "${AWS_SSH_USER}@${AWS_HOST}" \
  'echo AWS_SSH_CONNECTION_OK; docker --version'

ansible-playbook \
  -i "${AWS_HOST}," \
  -u "$AWS_SSH_USER" \
  --private-key "$AWS_SSH_KEY" \
  ansible/deploy-aws.yml

echo "===== STAGE 7: VERIFY PUBLIC AWS DASHBOARD ====="
AWS_HTML="$(mktemp)"
AWS_HTTP_CODE="$(curl --silent --show-error \
  --output "$AWS_HTML" \
  --write-out '%{http_code}' \
  --retry 10 --retry-delay 2 --retry-connrefused \
  "http://${AWS_HOST}/")"

echo "AWS_HTTP_STATUS=${AWS_HTTP_CODE}"
test "$AWS_HTTP_CODE" = "200"
grep -q "Powernet IT Service Dashboard" "$AWS_HTML"
rm -f "$AWS_HTML"

echo "===== ALL PIPELINE STAGES PASSED ====="
echo "AWS DEPLOYMENT VERIFIED"
