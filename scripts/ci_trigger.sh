#!/usr/bin/env sh

set -x

TOKEN=${TOKEN:-$CIRCLECI_TRIGGER_API_TOKEN}

CIRCLE_BRANCH=${CIRCLE_BRANCH:?must be set!}

__check() {
    yq e -e ".workflows.$1" .circleci/config.yml > /dev/null \
        || (>&2 echo "Did not detect specialized workflow for '$1'" && false)
}

__exec() {
    curl -D /dev/stdout -o /dev/stderr -sS -X POST \
        --url https://circleci.com/api/v2/project/gh/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pipeline \
        --header "Circle-Token: $TOKEN" \
        --header 'content-type: application/json' \
        --data @- <<EOF | grep -qE '^HTTP.+ 2\d{2}'
{
  "branch": "$CIRCLE_BRANCH",
  "parameters": {
    "specialization": "$1"
  }
}
EOF
}

CMD=$1

shift 1

case $CMD in
    check)
        __check $1
    ;;
    exec)
        __exec $1
    ;;
    *)
        >&2 echo "Unrecognized command: $CMD"
        false
    ;;
esac || exit 1
