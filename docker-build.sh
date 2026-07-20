#!/usr/bin/env bash
set -e

MODE=${MODE:-release}

case "${1:-android}" in
  android)
    echo "=== BMDesk Android Build (Docker) ==="
    docker build -t bmdesk-android -f Dockerfile.android .
    docker run --rm -v "$(pwd):/workspace" -e MODE="$MODE" bmdesk-android
    ;;
  windows)
    echo "=== BMDesk Windows Build ==="
    echo "Windows builds must run on a Windows host or Windows container."
    if [ "$(uname -s)" = "Linux" ]; then
      echo "ERROR: Cannot build Windows target from Linux host."
      exit 1
    fi
    python3 build.py --flutter "$@"
    ;;
  *)
    echo "Usage: $0 [android|windows] [--conn-type incoming|outgoing]"
    exit 1
    ;;
esac

echo "Done."
