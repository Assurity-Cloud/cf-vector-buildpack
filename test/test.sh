#!/usr/bin/env bash

shunit2_location=""
shunit2_location="$(which shunit2)" || {
  curl -sLo shunit2 https://raw.githubusercontent.com/kward/shunit2/master/shunit2
  chmod +x shunit2
  shunit2_location=$PWD/shunit2
}

setUp() {
  read -r -d '' VCAP_SERVICES <<-EOF
{
  "csb-aws-influxdb": [
    {
      "label": "csb-aws-influxdb",
      "provider": null,
      "plan": "default",
      "name": "influxdb1",
      "tags": [
        "aws",
        "influxdb",
        "preview"
      ],
      "instance_guid": "22f79fd5-4e7d-4b4e-9a16-51e89e1f0ba0",
      "instance_name": "cloudflare-influxdb",
      "binding_guid": "4f7010ff-d6b5-4d50-8810-36d518616c87",
      "binding_name": "influxdb1",
      "credentials": {
        "admin_password": "u@E{j=Bl#n[!&9Gw?BCXWyHyZY309eH]<f_jESElCn56U@0x@fyFne<hys%Z&6j?",
        "admin_username": "5uDsBrPEVg0Z8UrriDkmIKn2bdjjmbwU",
        "bound_database": "db",
        "databases": "[\"db\"]",
        "default_database": "db",
        "hostname": "cloudflare.ap-org-demo.csb.service",
        "password": "63T!LT@Mk5dE>8(x]lQ0ljLwrf{xpp/+#cS9cS&%YU&u?kM$+Esi1b4>pVvIIr}n",
        "port": 443,
        "protocol": "HTTPS",
        "retention_policies": "{}",
        "url": "HTTPS://cloudflare.ap-org-demo.csb.service:443",
        "username": "0ClTLJ7YpZhLrFwaYBcTzjg0xA4zdTuA"
      },
      "syslog_drain_url": null,
      "volume_mounts": []
    }
  ]
}
EOF
  export VCAP_SERVICES="${VCAP_SERVICES}"
  echo $VCAP_SERVICES
  export APP_ROOT=$PWD/tmp
  mkdir -p "${APP_ROOT}"

  source functions.sh
  set +e # Undo fail fast from main.sh


}

tearDown() {
  if [ -d "${APP_ROOT}" ]; then
    rm -r "${APP_ROOT}"
  fi
}

test_set_provisioned_services_sets_password_with_control_characters() {

  # Given there is a configuration file with a placeholder for a password containing control characters
  export PROVISIONED_SERVICE_BINDING_NAMES=influxdb1
  cat <<-EOF > "${APP_ROOT}/test.yml"
test_password: \${influxdb1.credentials.password}
EOF

  # When we call set_provisioned_services
  set_provisioned_services
  processExitCode=$?
  assertEquals 0 "${processExitCode}"

  # The placeholder gets substituted for the correct value
  assertEquals "test_password: 63T!LT@Mk5dE>8(x]lQ0ljLwrf{xpp/+#cS9cS&%YU&u?kM$+Esi1b4>pVvIIr}n" "$(cat ${APP_ROOT}/test.yml)"
}

test_set_provisioned_services_sets_url() {

  # Given there is a configuration file with a placeholder for a url
  export PROVISIONED_SERVICE_BINDING_NAMES=influxdb1
  cat <<-EOF > "${APP_ROOT}/test.yml"
test_url: \${influxdb1.credentials.url}
EOF

  # When we call set_provisioned_services
  set_provisioned_services
  processExitCode=$?
  assertEquals 0 "${processExitCode}"

  # The placeholder gets substituted for the correct value
  assertEquals "test_url: HTTPS://cloudflare.ap-org-demo.csb.service:443" "$(cat ${APP_ROOT}/test.yml)"
}


test_set_provisioned_services_sets_databases() {

  # Given there is a configuration file with a placeholder for a list of databases
  export PROVISIONED_SERVICE_BINDING_NAMES=influxdb1
  cat <<-EOF > "${APP_ROOT}/test.yml"
test_databases: \${influxdb1.credentials.databases}
EOF

  # When we call set_provisioned_services
  set_provisioned_services
  processExitCode=$?
  assertEquals 0 "${processExitCode}"

  # The placeholder gets substituted for the correct value
  assertEquals "test_databases: [\"db\"]" "$(cat ${APP_ROOT}/test.yml)"
}

test_set_provisioned_services_no_matching_data() {

  # Given there is a configuration file with a placeholder and a matching binding name that isn't in VCAP_SERVICES
  export PROVISIONED_SERVICE_BINDING_NAMES=not_this_one
  cat <<-EOF > "${APP_ROOT}/test.yml"
test_username: \${not_this_one.credentials.username}
EOF

  # When we call set_provisioned_service
  set_provisioned_services
  processExitCode=$?
  assertEquals 0 "${processExitCode}"

  # The placeholder remains
  assertEquals "test_username: \${not_this_one.credentials.username}" "$(cat ${APP_ROOT}/test.yml)"
}


# Run tests by sourcing shunit2
source "${shunit2_location}"
