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
			*) "$CONFMAN_LOG" error 'Aborting..'; exit 1;;
		esac

		unset RESPONSE
	fi
}

is_platform_compatible() {
	if ! [ -r "$1" ]; then
		"$CONFMAN_LOG" error "the file supplied as argument to function 'is_platform_compatible' cannot be read: $1"
		return 1
	fi

	uname -s | grep -i -q -f "$1"
}

verify_execute_permission() {
	if [ ! -x "$1" ]; then
		"$CONFMAN_LOG" warning "Adding execute permission to file '$1'"
		if ! chmod ug+x "$1" 2>/dev/null; then
			"$CONFMAN_LOG" warning "User '$(whoami)' does not have permission to 'chmod' file '$1'. Requesting 'chmod ug+x' on file with 'sudo'.."
			sudo chmod ug+x "$1"
		fi
	fi
}

