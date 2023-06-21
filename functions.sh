#!/usr/bin/env bash
set -euo pipefail

get_binding_service() {
    local binding_name="${1}"
    jq --arg b "${binding_name}" '.[][] | select(.binding_name == $b)' <<<"${VCAP_SERVICES}"
}

substitute_provisioned_service_values() {
  local placeholder="${1}"
  local value="$(printf "%q" "${2}")"

  if [[ ${value} == *"/"* ]]; then
    value="$(echo "${value}" | sed "s#/#\\\/#g")"
  fi

  echo "Replacing ${placeholder} with ${value} in ${APP_ROOT}/**.*ml"

  sed -i -- "s/\${${placeholder}}/${value}/g" ${APP_ROOT}/**.*ml
}

iterate_provisioned_service_values() {
  local name_prefix="${1}"
  local json=${2}

  echo "${json}" | jq -c -r 'to_entries | .[] | select(.value | scalars)' | while read -r i; do
    substitute_provisioned_service_values "${name_prefix}.$(echo "${i}" | jq -r '.key')" "$(echo "${i}" | jq -r '.value')"
  done
  echo "${json}" | jq -c -r 'to_entries | .[] | select(.value | iterables)' | while read -r i; do
    iterate_provisioned_service_values "${name_prefix}.$(echo "${i}" | jq -r '.key')" "$(echo "${i}" | jq -r '.value')"
  done
}

set_provisioned_service() {
  provisioned_service_binding="${1}"
  provisioned_service="$(get_binding_service "${provisioned_service_binding}")"
  if [[ -n "${provisioned_service}" ]]; then
    echo "Setting provisioned_service ${provisioned_service_binding}"
    iterate_provisioned_service_values "${provisioned_service_binding}" "${provisioned_service}"
  fi
}

set_provisioned_services() {
  echo "Provisioned service binding names: ${PROVISIONED_SERVICE_BINDING_NAMES}"
  if [[ ! -z ${PROVISIONED_SERVICE_BINDING_NAMES} ]]; then
    for provisioned_service_binding in ${PROVISIONED_SERVICE_BINDING_NAMES//,/ }; do
      echo "Looking for provisioned_service ${provisioned_service_binding}"
      set_provisioned_service "${provisioned_service_binding}"
    done
  fi
}

