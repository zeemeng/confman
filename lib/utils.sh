#!/usr/bin/env sh

print_blue () { printf "$CONFMAN_BLUE$@$CONFMAN_NC"; }

print_red () { printf "$CONFMAN_RED$@$CONFMAN_NC"; }

print_green () { printf "$CONFMAN_GREEN$@$CONFMAN_NC"; }

print_yellow () { printf "$CONFMAN_YELLOW$@$CONFMAN_NC"; }

prompt_continuation_or_exit() {
	# If CONFMAN_PROMPT is level 1 or level 2
	if [ "$CONFMAN_PROMPT" -ge 1 ]; then
		printf 'Are you sure you want to continue? (y)es / (n)o: '
		read RESPONSE
		case "$RESPONSE" in
			Y*|y*) printf '\n'; return 0;;
			*) confman_log error 'Aborting..'; exit 1;;
		esac

		unset RESPONSE
	fi
}

is_platform_compatible() {
	if ! [ -r "$1" ]; then
		confman_log error "the file supplied as argument to function 'is_platform_compatible' cannot be read: $1"
		return 1
	fi

	uname -s | grep -i -q -f "$1"
}

fix_permission_execute() {
	if [ ! -x "$1" ]; then
		confman_log warning "Adding execute permission to file '$1'"
		if ! chmod ug+x "$1" 2>/dev/null; then
			confman_log warning "User '$(whoami)' does not have permission to 'chmod' file '$1'. Requesting 'chmod ug+x' on file with 'sudo'.."
			sudo chmod ug+x "$1"
		fi
	fi

	"$1"
}

confman_log () {
	if [ $# -lt 2 ]; then
		printf "${CONFMAN_RED}${CONFMAN_PREFIX_ERROR}%s${CONFMAN_NC}\n" "confman_log has been invoked with $# parameters, but requires at least 2." >&2
		exit 1
	fi

	case "$1" in
		info) shift && printf "${CONFMAN_BLUE}${CONFMAN_PREFIX_NORMAL}${CONFMAN_NC}$@${CONFMAN_NC}\n";;
		success) shift && printf "${CONFMAN_GREEN}${CONFMAN_PREFIX_NORMAL}$@${CONFMAN_NC}\n";;
		warning) shift && printf "${CONFMAN_YELLOW}${CONFMAN_PREFIX_WARNING}$@${CONFMAN_NC}\n" >&2;;
		error) shift && printf "${CONFMAN_RED}${CONFMAN_PREFIX_ERROR}$@${CONFMAN_NC}\n" >&2;;
		hl_red) shift && printf "${CONFMAN_RED}$@${CONFMAN_NC}";;
		hl_green) shift && printf "${CONFMAN_GREEN}$@${CONFMAN_NC}";;
		hl_yellow) shift && printf "${CONFMAN_YELLOW}$@${CONFMAN_NC}";;
		hl_blue) shift && printf "${CONFMAN_BLUE}$@${CONFMAN_NC}";;
		*) printf "${CONFMAN_RED}${CONFMAN_PREFIX_ERROR}%s${CONFMAN_NC}\n" "the first argument to confman_log has an unsupported value: $1" >&2 && exit 1
	esac
}

