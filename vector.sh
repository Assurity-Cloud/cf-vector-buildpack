#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -euo pipefail

ROOT="${ROOT:-/home/vcap}"
export APP_ROOT="${ROOT}/app"
export VECTOR_ROOT="${VECTOR_ROOT}"
export VECTOR_OPTS=${VECTOR_OPTS}
export PROVISIONED_SERVICE_BINDING_NAMES=${PROVISIONED_SERVICE_BINDING_NAMES:-""}

source functions.sh
set_provisioned_services

config=""
for f in $(ls ${APP_ROOT}/*.toml | grep -v "test-"); do
  config="${config} -c ${f}"
done

echo "Starting vector with config files:${config}"

$(${VECTOR_ROOT}/bin/vector ${VECTOR_OPTS}${config})