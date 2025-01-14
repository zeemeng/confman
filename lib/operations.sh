#!/usr/bin/env sh

print_usage_exit() {
	cat <<- EOF
	USAGE:
	confman [-iIcb] [-m pkg_mgr] [-d config_dest] [-r config_repo] [-p prompt_lvl] [-f pkg_list] [package ...]
	confman [-uUxb] [-m pkg_mgr] [-d config_dest] [-r config_repo] [-p prompt_lvl] [-f pkg_list] [package ...]
	confman [-l] [-f pkg_list] [package ...]
	confman -D default_op [-m pkg_mgr] [-d config_dest] [-r config_repo] [-p prompt_lvl] [package]
	confman -L log_lvl log_msg
	confman [-vhH]

	EOF
	exit 1
}

print_version_exit() {
	printf "confman $CONFMAN_VERSION\n"
	exit 0
}

show_manpage_exit() {
	man "$CONFMAN_MAN_PATH/confman.1"
	exit 0
}

locate_data_path () {
	if [ -d "$HOME/.confman" ]; then printf "$HOME/.confman"; return 0; fi
	if [ "$XDG_CONFIG_HOME" ] && [ -d "$XDG_CONFIG_HOME/confman" ]; then printf "$XDG_CONFIG_HOME/confman"; return 0; fi
	if [ -d "$HOME/.config/confman" ]; then printf "$HOME/.config/confman"; return 0; fi
	printf "$HOME/.confman"
}

add_bindir_to_PATH () {
	case "$PATH" in
		*"$CONFMAN_BIN_PATH"*) ;;
		'') PATH="$CONFMAN_BIN_PATH";;
		':') PATH="$CONFMAN_BIN_PATH:";;
		*) PATH="$CONFMAN_BIN_PATH:$PATH";;
	esac
}

append_skip_list () { SKIP_PKGS="${SKIP_PKGS}${PKG}\n"; }
append_skip_list () { SKIP_PKGS="${SKIP_PKGS}${PKG}\n"; }
append_undefined_list () { UNDEFINED_PKGS="${UNDEFINED_PKGS}${PKG}\n"; }
append_requested_list () { REQUESTED_PKGS="${REQUESTED_PKGS}${PKG}\n"; }
append_install_list () { INSTALL_PKGS="${INSTALL_PKGS}${PKG}\n"; }
append_configure_list () { SETUP_PKGS="${SETUP_PKGS}${PKG}\n"; }

# Depends on pre-defined variables: CONFMAN_REPO, PKG, REQUESTED_PKGS, INSTALL_PKGS, SETUP_PKGS, SKIP_PKGS
append_to_pkg_lists() {
	PKG_DIR="$CONFMAN_REPO/$PKG"

	# Check if PKG contains any non-whitespace character. If it does, continue, otherwise return
	if ! printf '%s\n' "$PKG" | grep -q "[^[:space:]]"; then return; fi

	# PKGs not defined in a confman config repository are not processed
	if [ ! -d "$PKG_DIR" ]; then append_undefined_list; return 0; fi

	# Append to the list of requested pkgs
	append_requested_list

	DO_INSTALL=1; DO_CONFIGURE=1
	if [ -s "$PKG_DIR/pkg.conf" ]; then evaluate_pkgconf --selections; fi
	if [ -f "$PKG_DIR/noinstall" ]; then unset -v DO_INSTALL; fi
	if [ -f "$PKG_DIR/noconfigure" ]; then unset -v DO_CONFIGURE; fi
	if [ ! -d "$PKG_DIR/data" ] && [ ! -f "$PKG_DIR/preconfigure" ] && [ ! -f "$PKG_DIR/configure" ]; then unset -v DO_CONFIGURE; fi

	if [ "$DO_CONFIGURE" ]; then append_configure_list; fi
	if [ "$DO_INSTALL" ]; then append_install_list; fi
	if [ ! "$DO_CONFIGURE" ] && [ ! "$DO_INSTALL" ]; then append_skip_list; fi
}

read_selected_packages() {
	unset -v UNDEFINED_PKGS REQUESTED_PKGS INSTALL_PKGS SETUP_PKGS SKIP_PKGS

	# Select packages from operands
	for PKG in "$@"; do append_to_pkg_lists; done

	# If specified file exists and can be read, select packages from file line-by-line
	if [ -f "$PKG_FILE" ] && [ -r "$PKG_FILE" ]; then
		while read -r PKG; do append_to_pkg_lists; done < "$PKG_FILE"
	elif [ "$PKG_FILE" ]; then
		confman_log warning "Cannot read package list file. Defaulting to select all packages from repository."
		prompt_continuation_or_exit
		unset -v PKG_FILE;
	fi

	# If no operand and no package-list file is specified, select all packages from the target package repository
	if [ "$#" -eq 0 ] && [ ! "$PKG_FILE" ]; then
		while read -r PKG; do if [ -d "$CONFMAN_REPO/$PKG" ]; then append_to_pkg_lists; fi; done <<-EOF
			$(ls -1AL "$CONFMAN_REPO")
		EOF
	fi

	# Sort and remove duplicate items in PKG lists
	UNDEFINED_PKGS="$(printf "$UNDEFINED_PKGS" | sort -u)"
	REQUESTED_PKGS="$(printf "$REQUESTED_PKGS" | sort -u)"
	INSTALL_PKGS="$(printf "$INSTALL_PKGS" | sort -u)"
	SETUP_PKGS="$(printf "$SETUP_PKGS" | sort -u)"
	SKIP_PKGS="$(printf "$SKIP_PKGS" | sort -u)"

	if [ "$UNDEFINED_PKGS" ]; then
		confman_log warning "Skipping package(s) not defined in the confman repository:"
		printf "$UNDEFINED_PKGS\n\n"
	fi

	if [ "$l" != 1 ] && [ "$SKIP_PKGS" ]; then
		confman_log warning "Skipping the following package(s) as they do not support the requested operation(s) on the current platform:"
		printf "$SKIP_PKGS\n\n"
	fi
}

print_selected_packages() {
	unset -v PKG_COLUMN PLATFORM_COLUMN INSTALL_COLUMN UNINSTALL_COLUMN CONFIG_COLUMN UNCONFIG_COLUMN
	PRINTF_FORMAT='%-31s%-31s%-31s%-31s%-31s%-31s\n'

	if [ -z "$REQUESTED_PKGS" ]; then confman_log info 'No confman managed package to list..'; return 0; fi

	get_column_label () {
		LABEL='default'
		if [ "$1" = 'configure' ] || [ "$1" = 'unconfigure' ] && [ ! -d "$PKG_DIR/data" ]; then LABEL='NO DATA'; fi
		if [ -f "$PKG_DIR/$1" ]; then LABEL='CUSTOM'; fi
		case "$1" in
			install|configure)
				if [ -f "$PKG_DIR/pre$1" ]; then LABEL="PRE, ${LABEL}"; fi
				if [ -f "$PKG_DIR/post$1" ]; then LABEL="${LABEL}, POST"; fi
				if [ -f "$PKG_DIR/no$1" ]; then LABEL="$(printf "no $1" | tr '[:lower:]' '[:upper:]')"; fi;;
			uninstall|unconfigure)
				if [ -f "$PKG_DIR/no${1#'un'}" ]; then LABEL="$(printf "no ${1#'un'}" | tr '[:lower:]' '[:upper:]')"; fi;;
		esac
		case "$LABEL" in
			'default') print_blue "$LABEL";;
			NO*) print_red "$LABEL";;
			*) print_yellow "$LABEL";;
		esac
	}

	# Print header
	printf "$PRINTF_FORMAT" \
		"`print_blue Package Name`" \
		"`print_blue Platform`" \
		"`print_blue Install`" \
		"`print_blue Uninstall`" \
		"`print_blue Configure`" \
		"`print_blue Unconfigure`"
	printf '%111s\n' | tr ' ' '='

	# Print PKG rows
	printf '%s\n' "$REQUESTED_PKGS" | while read -r PKG; do
		# Early return on blank lines
		if [ -z "$PKG" ]; then continue; fi
		PKG_DIR="$CONFMAN_REPO/$PKG"

		# "Package Name" column
		PKG_COLUMN="$(print_blue "$PKG")"

		# "Platform" column
		PLATFORM_COLUMN=`print_green All`
		if [ -f "$PKG_DIR/platform" ]; then
			PLATFORM_COLUMN=`print_yellow "$(sed -E -e ':a' -e 'N' -e '$!ba' -e 's/\n+/,/g; s/,$//' "$PKG_DIR/platform")"`
		fi

		# "Install", "Uninstall", "Configure", "Unconfigure" columns
		INSTALL_COLUMN="$(get_column_label install)"
		UNINSTALL_COLUMN="$(get_column_label uninstall)"
		CONFIG_COLUMN="$(get_column_label configure)"
		UNCONFIG_COLUMN="$(get_column_label unconfigure)"

		printf "$PRINTF_FORMAT" "$PKG_COLUMN" "$PLATFORM_COLUMN" "$INSTALL_COLUMN" "$UNINSTALL_COLUMN" "$CONFIG_COLUMN" "$UNCONFIG_COLUMN"
	done
	printf '\n'
}

dispatch_default_op () {
	case "$#" in
		0) ;;
		1) PKG="$1";;
		*) confman_log error 'too many operands'; print_usage_exit;;
	esac
	case "$D_OPTARG" in
		update|install|uninstall|configure|unconfigure) execute_operation "$D_OPTARG";;
		*) confman_log error "unrecognized argument value passed to option '-D': $1"; print_usage_exit;;
	esac
}

execute_operation() (
	unset -v DEFAULT_OR_CUSTOM SCRIPT

	case "$1" in
		update)
			fix_permission_execute "$CONFMAN_LIB_PATH/mgr/$CONFMAN_MGR/$1"; return $?;;
		pre*|post*)
			DEFAULT_OR_CUSTOM='custom'
			SCRIPT="$CONFMAN_REPO/$PKG/$1";;
		custom)
			DEFAULT_OR_CUSTOM='custom'
			SCRIPT="$CONFMAN_REPO/$PKG/$2"
			set -- "$2";;
		configure|unconfigure)
			DEFAULT_OR_CUSTOM='default'
			SCRIPT="$CONFMAN_LIB_PATH/default_op/$1";;
		install|uninstall)
			DEFAULT_OR_CUSTOM='default'
			SCRIPT="$CONFMAN_LIB_PATH/mgr/$CONFMAN_MGR/$1";;
	esac

	if [ ! "$D_OPTARG" ]; then
		confman_log info "Performing $DEFAULT_OR_CUSTOM $(print_blue "$1") for $(print_blue "$PKG")"
	fi

	if [ -s "$CONFMAN_REPO/$PKG/pkg.conf" ]; then evaluate_pkgconf --operations; fi

	if fix_permission_execute "$SCRIPT"; then
		confman_log success "SUCCESSFULLY performed $DEFAULT_OR_CUSTOM \"$1\" for \"$PKG\"\n"
	else
		confman_log error "An error occured during $DEFAULT_OR_CUSTOM \"$1\" for \"$PKG\"\n"
	fi
)

dispatch_operation() {
	unset -v TARGET_PKGS INPUT_DEVICE PKG_DIR

	# Update/sync back-end package manager repositories. Set options and environment variables
	case "$1" in
		install | uninstall) TARGET_PKGS="$INSTALL_PKGS" && execute_operation update; printf '\n';;
		configure | unconfigure) TARGET_PKGS="$SETUP_PKGS";;
		*) confman_log error "unrecognized argument value passed to function 'dispatch_operations': $1" && return 1;;
	esac

	if [ -z "$TARGET_PKGS" ]; then confman_log warning "No package available for $1.. Done."; return 0; fi
	confman_log info "Packages selected for $(print_blue "$1"):\n$TARGET_PKGS\n"
	prompt_continuation_or_exit

	case "$CONFMAN_PROMPT" in
		0) INPUT_DEVICE='/dev/null';;
		*) INPUT_DEVICE='/dev/tty';;
	esac

	printf '%s\n' "$TARGET_PKGS" | while read -r PKG; do
		PKG_DIR="$CONFMAN_REPO/$PKG"
		case "$1" in
			install | configure)
				if [ -f "$PKG_DIR/pre$1" ]; then execute_operation pre "pre$1"; fi
				if [ -f "$PKG_DIR/$1" ]; then execute_operation custom "$1"; else execute_operation "$1"; fi
				if [ -f "$PKG_DIR/post$1" ]; then execute_operation "post$1"; fi;;
			uninstall | unconfigure)
				if [ -f "$PKG_DIR/$1" ]; then execute_operation custom "$1"; else execute_operation "$1"; fi;;
		esac < "$INPUT_DEVICE"
	done
}

