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
	printf "${SETDOTS_BLUE}${SETDOTS_PREFIX_NORMAL}${SETDOTS_NC}$*\n"
}

log_success() {
	printf "${SETDOTS_GREEN}${SETDOTS_PREFIX_NORMAL}$*${SETDOTS_NC}\n"
}

log_warning() {
	printf "${SETDOTS_YELLOW}${SETDOTS_PREFIX_WARNING}$*${SETDOTS_NC}\n" >&2
}

log_error() {
	printf "${SETDOTS_RED}${SETDOTS_PREFIX_ERROR}$*${SETDOTS_NC}\n" >&2
}

highlight_string() {
	printf "${SETDOTS_BLUE}$*${SETDOTS_NC}"
}

print_usage_exit() {
	cat <<- EOF
	USAGE:
	setdots [-iIs] [-f package_list] [-m manager] [-p n] [package ...]
	setdots [-uUr] [-f package_list] [-m manager] [-p n] [package ...]
	setdots [-l] [-f package_list] [package ...]
	setdots [-vhH] 

	EOF
	exit 1
}

print_version_exit() {
	printf "setdots v0.1\n"
	exit 0
}

show_manpage_exit() {
	man "$SETDOTS_DIR/manpage/roff/setdots.1"
	exit 0
}

print_exit_invalid_options_combination() {
	log_error "Options -i, -I, and -s cannot be used in conjunction with options -u, -U, or -r"
	exit 1
}

