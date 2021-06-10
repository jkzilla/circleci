#!/bin/bash

if [ -z "${SNYK_TOKEN}" ]; then
  echo "[!]Please set SNYK_TOKEN variable in CircleCI project settings"
  exit 1
fi

if [ -z "${GITHUB_SNYK_TOKEN}" ]; then
  echo "[!]Please set GITHUB_SNYK_TOKEN variable in CircleCI project settings"
  exit 1
fi

## set threshold to "high" as critical not yet supported in Snyk iac
export SEVERITY_THRESHOLD=${SNYK_SEVERITY_THRESHOLD:="med"}

TAG_NAME=${CONTAINER_TAG:="latest"}

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

## set project path
PROJECT_PATH=$(eval echo ${CIRCLE_WORKING_DIRECTORY})

## set tag
SNYK_FNAME=snyk.json

## test 
snyk iac test --severity-threshold=${SEVERITY_THRESHOLD} --json > "${PROJECT_PATH}/${SNYK_FNAME}"

echo "[*] Finished snyk IAC test"

## parse results and check if we should comment back to GitHub
if [[ -z "${CIRCLE_PULL_REQUEST}" ]]; then
  echo "Not a pull request. Exiting"
else
  parse_and_post_comment "${PROJECT_PATH}/${SNYK_FNAME}"
fi
