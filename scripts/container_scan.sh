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
export SEVERITY_THRESHOLD=${SNYK_SEVERITY_THRESHOLD:="critical"}

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

## set tag
SNYK_FNAME=snyk.json

## set file location of scan results
export RESULTS=${HOME}/${SNYK_FNAME}

## test the repos language dependencies ( not the container )
echo "[*]starting snyk test of progamming language(s). Looking for manifest files..."
snyk test --severity-threshold=${SEVERITY_THRESHOLD} --all-projects --remote-repo-url="${CIRCLE_REPOSITORY_URL}" --json > ${RESULTS}

## send language dependencies scan result to Snyk
snyk monitor --all-projects --remote-repo-url="${CIRCLE_REPOSITORY_URL}"

echo "[*]Checking if we need to send results to GitHub"
if [[ -z "${CIRCLE_PULL_REQUEST}" ]]; then
  echo "[*]Not a pull request. Exiting"
else
  parse_and_post_comment "${RESULTS}"
  snyk monitor --docker ${CIRCLE_PROJECT_REPONAME}:${TAG_NAME} --file="${CIRCLE_WORKING_DIRECTORY}/Dockerfile"
fi
