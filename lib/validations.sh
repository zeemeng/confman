#!/usr/bin/env sh

# Technically unnecessary, since 'utils.sh' already sourced in main 'confman' script, but re-sourcing for clarity.
. "$CONFMAN_DIR/lib/utils.sh"

# Validate that the program is invoked appropriately and that the source directory could be found
validate_confman_path() {
	EXEC_NAME=confman
	CONFMAN_PATH="$(realpath "$0")"

	if [ ! -f "$CONFMAN_PATH" ] || [ "$(basename "$CONFMAN_PATH")" != "$EXEC_NAME" ]; then
		"$CONFMAN_LOG" error 'The location of the `confman` scripts cannot be determined. Are you sourcing the program via the `.` built-in? Please try executing `confman` as a command or pass it as the parameter to a POSIX shell.'
		sleep 2
		exit 1
	fi

	unset EXEC_NAME CONFMAN_PATH
}

validate_confman_repo() {
	if ! { [ -d "$CONFMAN_REPO" ] && [ -x "$CONFMAN_REPO" ]; }; then # CONFMAN_REPO specified, but cannot be read
		"$CONFMAN_LOG" warning "Cannot read from the specified package repository.. Defaulting to '$CONFMAN_DIR/packages'."
		CONFMAN_REPO="$CONFMAN_DIR/packages"
		prompt_continuation_or_exit
	fi
}

validate_confman_dest() {
	if ! [ -d "$CONFMAN_DEST" ]; then
		"$CONFMAN_LOG" warning "The specified package configuration destination '$CONFMAN_DEST' is not a valid directory.. Defaulting to '$HOME'."
		CONFMAN_DEST="$HOME"
		prompt_continuation_or_exit
	fi
}

validate_confman_prompt() {
	if { [ "$CONFMAN_PROMPT" != 0 ] && [ "$CONFMAN_PROMPT" != 1 ] && [ "$CONFMAN_PROMPT" != 2 ]; }; then
		"$CONFMAN_LOG" warning "The specified prompt level value '$CONFMAN_PROMPT' is invalid.. Defaulting to '1'."
		CONFMAN_PROMPT=1
		prompt_continuation_or_exit
	fi
}

validate_option_combinations() {
	if { [ "$i" ] || [ "$I" ] || [ "$s" ]; } && { [ "$u" ] || [ "$U" ] || [ "$r" ]; }; then
		"$CONFMAN_LOG" error "Options -i, -I, and -s cannot be used in conjunction with options -u, -U, or -r"
		exit 1
	fi
}

