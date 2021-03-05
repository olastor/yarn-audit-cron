#!/bin/bash

set -e # no error tolerance :/

# adjust values BELOW
TEMP_DIR="/tmp"
AUDIT_GROUPS="dependencies"
CRON_INTERVAL="60" # ... in minutes
WEBHOOK_URL=""

# gets called with markdown formatted message to alert something / somebody.
# Beware the escaping using jq if you're going to send JSON data
alert () {
  message="$1"

  # send alert message
  data=$(jq -n --arg MSG "${message}" '{ username: "Yarn Audit Bot", content: $MSG }')
  curl -s --retry 3 -X POST -H "Content-Type: application/json" -d "${data}" "${WEBHOOK_URL}"
}

# method for checking a project and possibly triggering the alert() method
# if the `YARN_AUDIT_SKIP_DATE` variable is set, then the cron interval is ignored.
check () {
  project_name="$1"
  base_url="$2" # url with which it is possible to append "/package.json", "/yarn.lock" and then download those files DIRECTLY using this url

  echo "Checking ${project_name}"

  temp_dir_id=$(date +%s%3N)
  temp_dir="${TEMP_DIR}/yarn-audit-cron-${temp_dir_id}"

  mkdir -p "${temp_dir}"

  curl -s --retry 3 "${base_url}/package.json" -o "${temp_dir}/package.json"
  curl -s --retry 3 "${base_url}/yarn.lock" -o "${temp_dir}/yarn.lock"

  iso_date_last_check=$(date --date "-${CRON_INTERVAL} min" --utc --iso-8601=seconds | cut -f1 -d'+')

  yarn audit --cwd "${temp_dir}" --groups "${AUDIT_GROUPS}" --json > "${temp_dir}/audit.json" 2> /dev/null

  if [[ ! -z "${YARN_AUDIT_SKIP_DATE}" ]]; then
    message=$(cat "${temp_dir}/audit.json" | jq -r 'select(.type == "auditAdvisory") | "\n_severity_: **\(.data.advisory.severity)**\n_report link_: **\(.data.advisory.url)**\n_dependency_: **\(.data.resolution.path)**"')
  else
    message=$(cat "${temp_dir}/audit.json" | jq -r --arg MIN_DATE "${iso_date_last_check}" 'select(.type == "auditAdvisory") | select(.data.advisory.created >= $MIN_DATE) | "\n_severity_: **\(.data.advisory.severity)**\n_report link_: **\(.data.advisory.url)**\n_dependency_: **\(.data.resolution.path)**"')
  fi

  if [[ -z "${message}" ]]; then
    echo "All good!"
  else
    echo "Found something, alerting..."
    alert "New vulnerabilities in **${project_name}**${message}"
  fi

  rm -rf "${temp_dir}"
}

# read projects list and check
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
while IFS=$'\t' read -r -a line
do
  check "${line[0]}" "${line[1]}"
done < "${DIR}/projects.tsv"
