#!/bin/bash

if [ -z "${SNYK_TOKEN}" ]; then
  echo "Please set SNYK_TOKEN variable in CircleCI project settings"
  exit 1
fi

## set threshold to critical
export SEVERITY_THRESHOLD=${SNYK_SEVERITY_THRESHOLD:="high"}

## auth
snyk auth ${SNYK_TOKEN}

## set organisation
snyk config set org=${SNYK_ORG}

## set disableSuggestions
snyk config set disableSuggestions=true

# Set env variables for Container Scanning
# First, find location of primary Dockerfile
# Second, re-tag the image to ensure Container Scan points to correct Docker Image
export DF_LOCATION=$(find . -name "Dockerfile" | head -n 1)
export TAG_NAME=${CONTAINER_TAG:="latest"}

# Always monitor for language dependencies
# Search for all language manifest filesand scan the dependencies ( i.e. gemfile.lock, poetry.lock, etc )
# the --command flag is only parsed for Python projects
echo "[*]Snyk test of progamming language(s). Looking for manifest files..."
snyk monitor --severity-threshold=${SEVERITY_THRESHOLD} --all-projects --command=python3


# Monitor for Docker image issues on PR or merge to Master/Main as this step takes minutes
if [ -z "${CIRCLE_PULL_REQUEST}" ] || [ "$CIRCLE_BRANCH" = "master" ] || [ "$CIRCLE_BRANCH" = "main" ]; then
  echo "[*]Container scan about to start..."
  echo "[*]Looking for issues with a ${SEVERITY_THRESHOLD} or higher."
  snyk container monitor \
    --severity-threshold=${SEVERITY_THRESHOLD} \
    --docker ${CIRCLE_PROJECT_REPONAME}:${TAG_NAME} \
    --file=${DF_LOCATION} \
    --exclude-base-image-vulns
  echo "[*]Scan results sent to Snyk."
fi
