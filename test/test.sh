#!/usr/bin/env bash

command -v shunit2 >/dev/null 2>&1 || { echo >&2 "please install 'shunit2'"; exit 1; }

setUp() {
  read -r -d '' VCAP_SERVICES <<-EOF
{
  "csb-aws-s3-bucket": [
    {
      "binding_guid": "7521aa96-a243-471e-bfc7-67460e4d73cd",
      "binding_name": "test",
      "credentials": {
        "access_key_id": "AKIAY5BTZYTHE7GA2LBM",
        "arn": "arn:aws:s3:::csb-348644dc-1b56-4e5f-830a-73f2590a3d22",
        "bucket_domain_name": "csb-348644dc-1b56-4e5f-830a-73f2590a3d22.s3.amazonaws.com",
        "bucket_name": "csb-348644dc-1b56-4e5f-830a-73f2590a3d22",
        "region": "ap-southeast-2",
        "secret_access_key": "GmOcKTrgADsIpfBIWrkOAByEfGMXMlGNnsOJvF18"
      },
      "instance_guid": "348644dc-1b56-4e5f-830a-73f2590a3d22",
      "instance_name": "my-test-s3-service",
      "label": "csb-aws-s3-bucket",
      "name": "my-test-s3-service",
      "plan": "private",
      "provider": null,
      "syslog_drain_url": null,
      "tags": [
        "aws",
        "s3",
        "preview"
      ],
      "volume_mounts": []
    }
  ]
}
EOF
  export VCAP_SERVICES="${VCAP_SERVICES}"
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

test_set_provisioned_service() {

  # Given there is a configuration file with a placeholder
  cat <<-EOF > "${APP_ROOT}/test.yml"
test_bucket_name: \${test.credentials.bucket_name}
EOF

  # When we call set_provisioned_service with a matching binding name
  set_provisioned_service "test"
  processExitCode=$?
  assertEquals 0 "${processExitCode}"

  # The placeholder gets substituted for the actual value
  assertEquals "test_bucket_name: csb-348644dc-1b56-4e5f-830a-73f2590a3d22" "$(cat ${APP_ROOT}/test.yml)"
}

test_set_provisioned_service_no_matching_data() {

  # Given there is a configuration file with a placeholder
  cat <<-EOF > "${APP_ROOT}/test.yml"
test_bucket_name: \${test.credentials.bucket_name}
EOF

  # When we call set_provisioned_service with a binding name that isn't in VCAP_SERVICES
  set_provisioned_service "not_this_one"
  processExitCode=$?
  assertEquals 0 "${processExitCode}"

  # The placeholder remains
  assertEquals "test_bucket_name: \${test.credentials.bucket_name}" "$(cat ${APP_ROOT}/test.yml)"
}

# Run tests by sourcing shunit2
shunit2_location="$(which shunit2)"
source "${shunit2_location}"
