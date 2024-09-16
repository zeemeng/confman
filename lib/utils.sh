#!/usr/bin/env sh

SETDOTS_RED='\033[1;31m'
SETDOTS_GREEN='\033[0;32m'
SETDOTS_YELLOW='\033[0;33m'
SETDOTS_BLUE='\033[0;36m'
SETDOTS_NC='\033[0m' # No Color
SETDOTS_PREFIX_NORMAL='SETDOTS: '
SETDOTS_PREFIX_WARNING='WARNING: '
SETDOTS_PREFIX_ERROR='ERROR: '

log_info() {
	printf "${SETDOTS_BLUE}${SETDOTS_PREFIX_NORMAL}${SETDOTS_NC}$@\n"
}

log_success() {
	printf "${SETDOTS_GREEN}${SETDOTS_PREFIX_NORMAL}$@${SETDOTS_NC}\n"
}

log_warning() {
	printf "${SETDOTS_YELLOW}${SETDOTS_PREFIX_WARNING}$@${SETDOTS_NC}\n" >&2
}

log_error() {
	printf "${SETDOTS_RED}${SETDOTS_PREFIX_ERROR}$@${SETDOTS_NC}\n" >&2
}

highlight_string() {
	printf "${SETDOTS_BLUE}$@${SETDOTS_NC}"
}

prompt_continuation_or_exit() {
	# If SETDOTS_PROMPT is level 1 or level 2
	if [ "$SETDOTS_PROMPT" -ge 1 ]; then
		printf 'Are you sure you want to continue? (y)es / (n)o: '
		read RESPONSE
		case "$RESPONSE" in
			Y*|y*) printf '\n'; return 0;;
			*) log_error 'Aborting..'; exit 1;;
		esac

		unset RESPONSE
	fi
}

