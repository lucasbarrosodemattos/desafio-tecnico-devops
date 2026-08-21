#!/bin/sh
set -eu

readonly HTML_FILE="/usr/share/nginx/html/index.html"
APP_VERSION="${APP_VERSION:-unknown}"

case "$APP_VERSION" in
    *[!A-Za-z0-9._-]*)
        printf 'ERROR: APP_VERSION contains unsupported characters: %s\n' "$APP_VERSION" >&2
        exit 1
        ;;
esac

if [ ! -f "$HTML_FILE" ]; then
    printf 'ERROR: HTML file not found: %s\n' "$HTML_FILE" >&2
    exit 1
fi

sed -i "s|__APP_VERSION__|${APP_VERSION}|g" "$HTML_FILE"

printf 'Application version injected: %s\n' "$APP_VERSION"