#!/bin/bash

if [ -z "${SNYK_TOKEN}" ]; then
  echo "Please set SNYK_TOKEN variable in CircleCI project settings"
  exit 1
fi

if [ -z "${GITHUB_SNYK_TOKEN}" ]; then
  echo "Please set GITHUB_SNYK_TOKEN variable in CircleCI project settings"
  exit 1
fi

## set threshold to critical
export SEVERITY_THRESHOLD=${SNYK_SEVERITY_THRESHOLD:="high"}

parse_and_post_comment () {
  scan_results=$(parse_scan_results $1)
  if [[ $scan_results ]]; then
      comment_on_pr "$scan_results"
  else
    echo "No scan results found in $1."
  fi
}

## auth
snyk auth ${SNYK_TOKEN}

## set organisation
snyk config set org=${SNYK_ORG}

## set file location of scan results
SNYK_FNAME=snyk.json
export RESULTS=${HOME}/${SNYK_FNAME}

# Search for all language manifest filesand scan the dependencies ( i.e. gemfile.lock, poetry.lock, etc )
echo "[*]Snyk test of progamming language(s). Looking for manifest files..."
snyk monitor --severity-threshold=${SEVERITY_THRESHOLD} --all-projects

echo "[*]Checking if results should be sent to GitHub"
if [[ -z "${CIRCLE_PULL_REQUEST}" ]]; then
  echo "[*]Not a pull request. No action."
else
  echo "[*]A pull request. Decoration of PR attempted for ${SEVERITY_THRESHOLD} issues."
  echo "[*]Not reporting Base Image vulnerabilities, by design."
  snyk container test \
    --severity-threshold=${SEVERITY_THRESHOLD} \
    --docker debian \
    --file=Dockerfile \
    --exclude-base-image-vulns \
    --file=${HOME}/Dockerfile \
    --json > ${RESULTS}
  parse_and_post_comment "${RESULTS}"
fi
