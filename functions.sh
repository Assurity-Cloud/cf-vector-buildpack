#!/usr/bin/env bash
set -euo pipefail

get_binding_service() {
    local binding_name="${1}"
    jq --arg b "${binding_name}" '.[][] | select(.binding_name == $b)' <<<"${VCAP_SERVICES}"
}

substitute_provisioned_service_values() {
  placeholder="${1}"
  value="${2}"

  sed -i -- "s/\${${placeholder}}/${value}/g" ${APP_ROOT}/**.*ml
}

iterate_provisioned_service_values() {
  name_prefix="${1}"
  json="${2}"

  echo "${json}" | jq -c 'to_entries | .[] | select(.value |  scalars)' | while read i; do
      substitute_provisioned_service_values "${name_prefix}.$(echo "${i}" | jq -r '.key')" "$(echo "${i}" | jq -r '.value')"
  done
  echo "${json}" | jq -c 'to_entries | .[] | select(.value |  iterables)' | while read i; do
      iterate_provisioned_service_values "${name_prefix}.$(echo "${i}" | jq -r '.key')" "$(echo "${i}" | jq '.value')"
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
  if [[ -z ${PROVISIONED_SERVICE_BINDING_NAMES} ]]; then
    for provisioned_service_binding in ${PROVISIONED_SERVICE_BINDING_NAMES//,/ }; do
      set_provisioned_service "${provisioned_service_binding}"
    done
  fi
}

