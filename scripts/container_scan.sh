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

## auth
snyk auth ${SNYK_TOKEN}

## set organisation
snyk config set org=${SNYK_ORG}

# Search for all language manifest filesand scan the dependencies ( i.e. gemfile.lock, poetry.lock, etc )
echo "[*]Snyk test of progamming language(s). Looking for manifest files..."
snyk monitor --severity-threshold=${SEVERITY_THRESHOLD} --all-projects

if [[ -z "${CIRCLE_PULL_REQUEST}" ]]; then
  echo "[*]Not a pull request. No action."
else
  echo "[*]A pull request. Printing issues with a ${SEVERITY_THRESHOLD} or higher."
  echo "[*]Not reporting Base Image vulnerabilities, by design."
  snyk container test \
    --severity-threshold=${SEVERITY_THRESHOLD} \
    --docker debian \
    --exclude-base-image-vulns \
    --file=${HOME}/Dockerfile
fi
