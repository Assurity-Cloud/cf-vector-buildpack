#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -euo pipefail

ROOT="${ROOT:-/home/vcap}"
export APP_ROOT="${ROOT}/app"
export VECTOR_ROOT="${VECTOR_ROOT}"
export VECTOR_OPTS=${VECTOR_OPTS:-"--quiet"}
export DATASOURCE_BINDING_NAMES=${DATASOURCE_BINDING_NAMES:-""}

source functions.sh
set_provisioned_services

$VECTOR_ROOT/bin/vector $VECTOR_OPTS --config ${APP_ROOT}/*.toml