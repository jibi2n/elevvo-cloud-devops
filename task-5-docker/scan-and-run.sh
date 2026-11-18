#!/usr/bin/env bash
set -euo pipefail
IMAGE=elevvo-task5-web:1.0
docker compose build
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 "$IMAGE"
echo "Scan passed, starting stack"
docker compose up -d


