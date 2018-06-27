#!/bin/sh
set -e

isCommand() {
  for cmd in \
    "help" \
    "list" \
    "parse" \
    "run" \
    "transform" \
    "project:parse" \
    "project:run" \
    "project:transform" \
    "template:generate" \
    "template:list" \
    "template:package"
  do
    if [ -z "${cmd#"$1"}" ]; then
      return 0
    fi
  done

  return 1
}

if [ "${1:0:1}" = "-" ]; then
  set -- /sbin/tini -- php /composer/vendor/bin/phpdoc "$@"
elif [ "$1" = "/composer/vendor/bin/phpdoc" ]; then
  set -- /sbin/tini -- php "$@"
elif [ "$1" = "phpdoc" ]; then
  set -- /sbin/tini -- php /composer/vendor/bin/"$@"
elif isCommand "$1"; then
  set -- /sbin/tini -- php /composer/vendor/bin/phpdoc "$@"
fi

exec "$@"
