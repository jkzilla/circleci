#!/usr/bin/env python3

import os
import sys


def help_message(error):
    if error:
        print(error, file=sys.stderr)

    print(
        """
Usage: print_env <target>

    <target> - the variable prefix to match

    Example: a target of FOO will match all variables starting FOO_
             such as FOO_TEST1 and FOO_TEST2
""",
        file=sys.stderr,
    )


def print_env(target):

    prefix = "%s_" % target
    prefixed_vars = [(name, value) for name, value in os.environ.items() if name.startswith(prefix)]
    
    if len(prefixed_vars) == 0:
        print("No variables found starting with %s_" % target, file=sys.stderr)
        sys.exit(1)

    for name, value in prefixed_vars:
        new_name = name[len(prefix):]
        print("export %s=%s" % (new_name, value))


def main(args):
    if len(args) != 1:
        help_message("Exactly one argument required")
        sys.exit(1)

    target = args[0]

    if not target:
        help_message("Prefix cannot be empty")
        sys.exit(1)

    print_env(target)


if __name__ == "__main__":
    main(sys.argv[1:])
