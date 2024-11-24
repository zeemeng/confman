#!/usr/bin/env sh
# To be run from root of Git repository

VERSION_FILE='version'
SRC_FILE='doc/src/confman.1.md'
OUT_FILE='doc/man/confman.1'

if [ -r "$VERSION_FILE" ] && [ -r "$SRC_FILE" ]; then
	TITLE='CONFMAN'
	SECTION='1'
	DATE="$(date +'%B %Y')"
	FOOTER="confman $(cat "$VERSION_FILE")"

	pandoc \
		--standalone \
		--to man \
		--output "$OUT_FILE" \
		--variable title="$TITLE" \
		--variable section="$SECTION" \
		--variable date="$DATE" \
		--variable footer="$FOOTER" \
		"$SRC_FILE"
else
	printf 'ERROR: man page source and/or version file not found.. Aborting\n' >&2
	exit 1
fi

