#!/bin/sh
set -e

# Default values
export KITSU_API_TARGET=${KITSU_API_TARGET:-http://host.docker.internal:5000}
export KITSU_EVENT_TARGET=${KITSU_EVENT_TARGET:-http://host.docker.internal:5001}

# Substitute environment variables in nginx config
envsubst '${KITSU_API_TARGET} ${KITSU_EVENT_TARGET}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

# Fix nginx variables ($$ becomes $)
sed -i 's/\$\$/\$/g' /etc/nginx/conf.d/default.conf

exec "$@"
