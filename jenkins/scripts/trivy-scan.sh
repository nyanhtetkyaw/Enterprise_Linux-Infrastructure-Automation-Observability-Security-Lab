#!/bin/bash
set -e

IMAGE="$1"

trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  "$IMAGE"
