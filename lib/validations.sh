#!/usr/bin/env sh

validate_confman_repo() {
	if ! { [ -d "$CONFMAN_REPO" ] && [ -x "$CONFMAN_REPO" ]; }; then # CONFMAN_REPO specified, but cannot be read
		confman_log warning "Cannot read from the specified package repository.. Defaulting to '$CONFMAN_DATA_PATH/packages'."
		CONFMAN_REPO="$CONFMAN_DATA_PATH/packages"
		prompt_continuation_or_exit
	fi
}

validate_confman_dest() {
	if [ "$D_OPTARG" = 'configure' ] || [ "$D_OPTARG" = 'unconfigure' ]; then mkdir -p "$CONFMAN_DEST"; fi

	if ! [ -d "$CONFMAN_DEST" ]; then
		confman_log warning "The specified package configuration destination '$CONFMAN_DEST' is not a valid directory.. Defaulting to '$HOME'."
		CONFMAN_DEST="$HOME"
		prompt_continuation_or_exit
	fi
}

validate_confman_prompt() {
	if { [ "$CONFMAN_PROMPT" != 0 ] && [ "$CONFMAN_PROMPT" != 1 ] && [ "$CONFMAN_PROMPT" != 2 ]; }; then
		confman_log warning "The specified prompt level value '$CONFMAN_PROMPT' is invalid.. Defaulting to '1'."
		CONFMAN_PROMPT=1
		prompt_continuation_or_exit
	fi
}

validate_option_combinations() {
	if { [ "$i" ] || [ "$I" ] || [ "$c" ]; } && { [ "$u" ] || [ "$U" ] || [ "$x" ]; }; then
		confman_log error "Options -i, -I, and -s cannot be used in conjunction with options -u, -U, or -r"
		exit 1
	fi
}

validate_pkg_manager() {
	if [ -z "$CONFMAN_MGR" ]; then
		for MGR_DIR in $(ls -d "$CONFMAN_LIB_PATH/mgr/"*); do
			evaluate_confmanconf "$MGR_DIR/confman.conf"
		done
	elif ! command -v "$CONFMAN_MGR" >/dev/null; then
		confman_log error "No suitable package manager was found."
		exit 1
	fi
}

