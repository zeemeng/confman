#!/usr/bin/env sh

CONFMAN_RED='\033[1;31m'
CONFMAN_GREEN='\033[0;32m'
CONFMAN_YELLOW='\033[0;33m'
CONFMAN_BLUE='\033[0;36m'
CONFMAN_NC='\033[0m' # No Color
CONFMAN_PREFIX_NORMAL='CONFMAN: '
CONFMAN_PREFIX_WARNING='WARNING: '
CONFMAN_PREFIX_ERROR='ERROR: '

log_info() {
	printf "${CONFMAN_BLUE}${CONFMAN_PREFIX_NORMAL}${CONFMAN_NC}$@\n"
}

log_success() {
	printf "${CONFMAN_GREEN}${CONFMAN_PREFIX_NORMAL}$@${CONFMAN_NC}\n"
}

log_warning() {
	printf "${CONFMAN_YELLOW}${CONFMAN_PREFIX_WARNING}$@${CONFMAN_NC}\n" >&2
}

log_error() {
	printf "${CONFMAN_RED}${CONFMAN_PREFIX_ERROR}$@${CONFMAN_NC}\n" >&2
}

highlight_string() {
	printf "${CONFMAN_BLUE}$@${CONFMAN_NC}"
}

prompt_continuation_or_exit() {
	# If CONFMAN_PROMPT is level 1 or level 2
	if [ "$CONFMAN_PROMPT" -ge 1 ]; then
		printf 'Are you sure you want to continue? (y)es / (n)o: '
		read RESPONSE
		case "$RESPONSE" in
			Y*|y*) printf '\n'; return 0;;
			*) log_error 'Aborting..'; exit 1;;
		esac

		unset RESPONSE
	fi
}

