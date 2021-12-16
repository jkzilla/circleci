#!/usr/bin/env bash

set -e

USAGE="
Usage: print_env <target>

    <target> - the variable prefix to match

    Example: a target of FOO will match all variables starting FOO_
             such as FOO_TEST1 and FOO_TEST2
"

function error {
  echo -e "\n$1\n$USAGE" >&2 && exit 1
}

[[ $# == 0 ]] && error "Prefix cannot be empty"
[[ $# -gt 1 ]] && error "Exactly one argument required"

PREFIX=$1

for var in `eval 'echo ${!'$PREFIX'*}'`; do
  echo "export ${var#${PREFIX%_}*_}=${!var}"
done
