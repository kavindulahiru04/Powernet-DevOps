#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="${WORKSPACE:-$(pwd)}"
cd "$ROOT"

echo "=========================================="
echo "POWER​​NET DEVOPS PIPELINE STARTED"
echo "=========================================="

echo "===== STAGE 1: CHECK NODE.JS ====="
node --version
npm --version

echo "===== STAGE 2: RUN AUTOMATED TESTS ====="
cd "$ROOT/app"

APP_LOG="$(mktemp)"
node app.js > "$APP_LOG" 2>&1 &
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

echo "===== STAGE 4: DEPLOY USING ANSIBLE ====="
ansible-playbook -i 'localhost,' ansible/deploy-dashboard.yml

echo "===== STAGE 5: VERIFY DEPLOYMENT ====="
APP_IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' powernet-dashboard-container)"

if [ -z "$APP_IP" ]; then
  echo "FAIL: Could not obtain the dashboard container IP."
  exit 1
fi

HTTP_CODE="$(curl --silent --show-error --output /tmp/powernet-dashboard-check.html \
  --write-out '%{http_code}' "http://${APP_IP}:3000")"

echo "Dashboard HTTP status: $HTTP_CODE"
test "$HTTP_CODE" = "200"
grep -q "Powernet IT Service Dashboard" /tmp/powernet-dashboard-check.html

docker ps --filter name=powernet-dashboard-container \
  --format 'Container: {{.Names}} | Status: {{.Status}} | Ports: {{.Ports}}'

echo "=========================================="
echo "ALL PIPELINE STAGES PASSED"
echo "=========================================="
