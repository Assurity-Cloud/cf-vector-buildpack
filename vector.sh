#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -euo pipefail

ROOT="${ROOT:-/home/vcap}"
export APP_ROOT="${ROOT}/app"
export VECTOR_ROOT="${VECTOR_ROOT}"
export VECTOR_OPTS=${VECTOR_OPTS:-""}
export VECTOR_CONFIG_DIRS=${VECTOR_CONFIG_DIRS:-""}
export PROVISIONED_SERVICE_BINDING_NAMES=${PROVISIONED_SERVICE_BINDING_NAMES:-""}

source functions.sh
set_provisioned_services

config_files=""
config_dirs=""

if [[ ! -z ${VECTOR_CONFIG_DIRS} ]] ; then
  echo "VECTOR_CONFIG_DIRS present with value: ${VECTOR_CONFIG_DIRS}"
  for config_dir in ${VECTOR_CONFIG_DIRS//,/ }
  do
    config_dirs="${config_dirs} --config-dir ${config_dir}"
  done
else
  echo "VECTOR_CONFIG_DIRS not present, will start with all vector config files in app directory"
  config_dirs="--config-dir ${APP_ROOT}"
fi

echo "Starting vector with config config_dirs: ${config_dirs}"

$(${VECTOR_ROOT}/bin/vector ${VECTOR_OPTS}${config_dirs})
