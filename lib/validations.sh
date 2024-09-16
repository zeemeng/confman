#!/usr/bin/env sh

# Technically unnecessary, since 'utils.sh' already sourced in main 'setdots' script, but re-sourcing for clarity.
. "$SETDOTS_DIR/lib/utils.sh"

# Validate that the program is invoked appropriately and that the source directory could be found
validate_setdots_path() {
	EXEC_NAME=setdots
	SETDOTS_PATH="$(realpath "$0")"

	if [ ! -f "$SETDOTS_PATH" ] || [ "$(basename "$SETDOTS_PATH")" != "$EXEC_NAME" ]; then
		log_error 'The location of the `setdots` scripts cannot be determined. Are you sourcing the program via the `.` built-in? Please try executing `setdots` as a command or pass it as the parameter to a POSIX shell.'
		sleep 2
		exit 1
	fi

	unset EXEC_NAME
}

validate_pkg_repo() {
	# Set default value **if** unassigned
	PKG_REPO="${PKG_REPO-$SETDOTS_DIR/packages}"

	if ! { [ -d "$PKG_REPO" ] && [ -x "$PKG_REPO" ]; }; then # PKG_REPO specified, but cannot be read
		log_warning "Cannot read from the specified package repository.. Defaulting to '$SETDOTS_DIR/packages'."
		PKG_REPO="$SETDOTS_DIR/packages"
		prompt_continuation_or_exit
	fi
}

validate_pkg_config_dest() {
	# Set default value **if** unassigned
	PKG_CONFIG_DEST="${PKG_CONFIG_DEST-$HOME}"

	if ! [ -d "$PKG_CONFIG_DEST" ]; then
		log_warning "The specified package configuration destination '$PKG_CONFIG_DEST' is not a valid directory.. Defaulting to '$HOME'."
		PKG_CONFIG_DEST="$HOME"
		prompt_continuation_or_exit
	fi
}

validate_setdots_prompt() {
	# Set default value **if** unassigned
	SETDOTS_PROMPT="${SETDOTS_PROMPT-1}"

	if { [ "$SETDOTS_PROMPT" != 0 ] && [ "$SETDOTS_PROMPT" != 1 ] && [ "$SETDOTS_PROMPT" != 2 ]; }; then
		log_warning "The specified prompt level value '$SETDOTS_PROMPT' is invalid.. Defaulting to '1'."
		SETDOTS_PROMPT=1
		prompt_continuation_or_exit
	fi
}

validate_option_combinations() {
	if { [ "$i" ] || [ "$I" ] || [ "$s" ]; } && { [ "$u" ] || [ "$U" ] || [ "$r" ]; }; then
		log_error "Options -i, -I, and -s cannot be used in conjunction with options -u, -U, or -r"
		exit 1
	fi
}

