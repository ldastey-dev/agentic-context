#!/bin/bash
# deploy.sh — compatibility shim. The deploy script lives in scripts/deploy.sh.
#
# Kept so existing instructions and automation that call ./deploy.sh from the
# repository root keep working. New usage should call scripts/deploy.sh.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/deploy.sh" "$@"
