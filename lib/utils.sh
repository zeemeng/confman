#!/usr/bin/env sh

prompt_continuation_or_exit() {
	# If CONFMAN_PROMPT is level 1 or level 2
	if [ "$CONFMAN_PROMPT" -ge 1 ]; then
		printf 'Are you sure you want to continue? (y)es / (n)o: '
		read RESPONSE
		case "$RESPONSE" in
			Y*|y*) printf '\n'; return 0;;
			*) "$CONFMAN_LOG" error 'Aborting..'; exit 1;;
		esac

		unset RESPONSE
	fi
}

