#!/usr/bin/env sh

REQUESTED_PKGS=
INSTALL_PKGS=
SETUP_PKGS=
SKIP_PKGS=
PKG_DIR=
NEW_LINE='
'

# Technically unnecessary, since 'utils.sh' already sourced in main 'confman' script, but re-sourcing for clarity.
. "$CONFMAN_DIR/lib/utils.sh"

print_usage_exit() {
	cat <<- EOF
	USAGE:
	confman [-iIs] [-m pkg_mgr] [-d config_dest] [-g config_repo] [-p prompt_lvl] [-f pkg_list] [package ...]
	confman [-uUr] [-m pkg_mgr] [-d config_dest] [-g config_repo] [-p prompt_lvl] [-f pkg_list] [package ...]
	confman [-l] [-f pkg_list] [package ...]
	confman [-vhH]

	EOF
	exit 1
}

print_version_exit() {
	printf "confman $(cat "$CONFMAN_DIR/version")\n"
	exit 0
}

show_manpage_exit() {
	man "$CONFMAN_DIR/doc/man/confman.1"
	exit 0
}

warn_about_skipped_packages() {
	if [ -z "$SKIP_PKGS" ]; then return; fi

	"$CONFMAN_LOG" warning "Skipping the following package(s) as they do not support the requested operation(s) on the current platform:"
	printf "$SKIP_PKGS\n\n"
}

# Depends on pre-defined variables: CONFMAN_REPO, PKG, REQUESTED_PKGS, INSTALL_PKGS, SETUP_PKGS, SKIP_PKGS, NEW_LINE
append_to_pkg_lists() {
	PKG_DIR="$CONFMAN_REPO/$PKG"

	# Check if PKG contains any non-whitespace character. If it does, continue, otherwise return
	if ! echo "$PKG" | grep -q "[^[:space:]]"; then return; fi

	# Skip the meta package 'default' which holds the default PKG scripts
	if [ "default" = "$PKG" ]; then return; fi

	# Append to the list of requested pkgs
	REQUESTED_PKGS="${REQUESTED_PKGS}${PKG}${NEW_LINE}"

	# If any line in the "$PKG_DIR/platform" file is a case insensitive BRE matching any part
	# of the output of `uname -s`, continue processing, else return.
	if [ -f "$PKG_DIR/platform" ] && ! is_platform_compatible "$PKG_DIR/platform"; then
		SKIP_PKGS="${SKIP_PKGS}${PKG}${NEW_LINE}"
		return
	fi

	if [ -f "$PKG_DIR/noinstall" ] && [ -f "$PKG_DIR/noconfigure" ]; then
		SKIP_PKGS="${SKIP_PKGS}${PKG}${NEW_LINE}"
		return
	fi

	if [ -f "$PKG_DIR/noinstall" ]; then
		SETUP_PKGS="${SETUP_PKGS}${PKG}${NEW_LINE}"
		return
	fi

	if [ -f "$PKG_DIR/noconfigure" ]; then
		INSTALL_PKGS="${INSTALL_PKGS}${PKG}${NEW_LINE}"
		return
	fi

	if [ -d "$PKG_DIR" ]; then
		SETUP_PKGS="${SETUP_PKGS}${PKG}${NEW_LINE}"
		INSTALL_PKGS="${INSTALL_PKGS}${PKG}${NEW_LINE}"
		return
	fi
}

read_selected_packages() {
	# Select packages from operands
	for PKG in "$@"; do append_to_pkg_lists; done

	# If specified file exists and can be read, select packages from file line-by-line
	if [ -f "$PKG_FILE" ] && [ -r "$PKG_FILE" ]; then
		while read -r PKG; do append_to_pkg_lists; done < "$PKG_FILE"

	# Specified file exists, but cannot be read
	elif [ "$PKG_FILE" ]; then
		"$CONFMAN_LOG" warning "Cannot read package list file. Defaulting to select all packages from repository."
		prompt_continuation_or_exit
		unset f;
	fi

	# If no operand and no package-list file is specified, select all packages from the target package repository
	if [ "$#" -eq 0 ] && [ ! "$PKG_FILE" ]; then
		while read -r PKG; do
			if [ -d "$CONFMAN_REPO/$PKG" ]; then append_to_pkg_lists; fi
		done <<-EOF
		$(ls -1A "$CONFMAN_REPO")
		EOF
	fi

	# Sort and remove duplicate items in PKG lists
	REQUESTED_PKGS="$(printf "$REQUESTED_PKGS" | sort -u)"
	INSTALL_PKGS="$(printf "$INSTALL_PKGS" | sort -u)"
	SETUP_PKGS="$(printf "$SETUP_PKGS" | sort -u)"
	SKIP_PKGS="$(printf "$SKIP_PKGS" | sort -u)"
}

print_exit_selected_packages() {
	PKG_COLUMN=
	PLATFORM_COLUMN=
	INSTALL_COLUMN=
	UNINSTALL_COLUMN=
	CONFIG_COLUMN=
	UNCONFIG_COLUMN=

	# Print header
	printf "%-31s%-31s%-31s%-31s%-31s%-31s\n" "`print_blue Package Name`" "`print_blue Platform`" "`print_blue Install`" "`print_blue Uninstall`" "`print_blue Configure`" "`print_blue Unconfigure`"
	printf "===============================================================================================================\n"

	printf '%s\n' "$REQUESTED_PKGS" | while read -r PKG; do
		PKG_DIR="$CONFMAN_REPO/$PKG"

		# "Package Name" column
		PKG_COLUMN=`$CONFMAN_LOG hl_blue "$PKG"`

		# "Platform" column
		if [ -f "$PKG_DIR/platform" ]; then
			PLATFORM_COLUMN="$(sed -E -e ':a' -e 'N' -e '$!ba' -e 's/\n+/,/g; s/,$//' "$PKG_DIR/platform")"
			PLATFORM_COLUMN=`print_yellow "$PLATFORM_COLUMN"`
		else
			PLATFORM_COLUMN=`print_green All`
		fi

		# "Install" and "Uninstall" columns
		INSTALL_COLUMN=''; UNINSTALL_COLUMN=''; # Reset vars for each iteration
		if [ -f "$PKG_DIR/noinstall" ]; then
			INSTALL_COLUMN='NO INSTALL'
			UNINSTALL_COLUMN='NO INSTALL'
		else
			if [ -f "$PKG_DIR/install" ]; then INSTALL_COLUMN='CUSTOM'; else INSTALL_COLUMN='default'; fi
			if [ -f "$PKG_DIR/preinstall" ]; then INSTALL_COLUMN="${INSTALL_COLUMN}, PRE"; fi
			if [ -f "$PKG_DIR/postinstall" ]; then INSTALL_COLUMN="${INSTALL_COLUMN}, POST"; fi
			if [ -f "$PKG_DIR/uninstall" ]; then UNINSTALL_COLUMN='CUSTOM'; else UNINSTALL_COLUMN='default'; fi
		fi
		case "$INSTALL_COLUMN" in
			'default') INSTALL_COLUMN=`print_blue "$INSTALL_COLUMN"`;;
			'NO INSTALL') INSTALL_COLUMN=`print_red "$INSTALL_COLUMN"`;;
			*) INSTALL_COLUMN=`print_yellow "$INSTALL_COLUMN"`
		esac
		case "$UNINSTALL_COLUMN" in
			'default') UNINSTALL_COLUMN=`print_blue "$UNINSTALL_COLUMN"`;;
			'NO INSTALL') UNINSTALL_COLUMN=`print_red "$UNINSTALL_COLUMN"`;;
			*) UNINSTALL_COLUMN=`print_yellow "$UNINSTALL_COLUMN"`
		esac

		# "Configure" and "Unconfigure" column
		CONFIG_COLUMN=''; UNCONFIG_COLUMN=''; # Reset vars for each iteration
		if [ -f "$PKG_DIR/noconfigure" ]; then
			CONFIG_COLUMN="NO CONFIGURE"
			UNCONFIG_COLUMN="NO CONFIGURE"
		else
			if [ -f "$PKG_DIR/configure" ]; then CONFIG_COLUMN="CUSTOM"; else CONFIG_COLUMN="default"; fi
			if [ -f "$PKG_DIR/preconfigure" ]; then CONFIG_COLUMN="${CONFIG_COLUMN}, PRE"; fi
			if [ -f "$PKG_DIR/postconfigure" ]; then CONFIG_COLUMN="${CONFIG_COLUMN}, POST"; fi
			if [ -f "$PKG_DIR/unconfigure" ]; then UNCONFIG_COLUMN="CUSTOM"; else UNCONFIG_COLUMN="default"; fi
		fi
		case "$CONFIG_COLUMN" in
			'default') CONFIG_COLUMN=`print_blue "$CONFIG_COLUMN"`;;
			'NO CONFIGURE') CONFIG_COLUMN=`print_red "$CONFIG_COLUMN"`;;
			*) CONFIG_COLUMN=`print_yellow "$CONFIG_COLUMN"`
		esac
		case "$UNCONFIG_COLUMN" in
			'default') UNCONFIG_COLUMN=`print_blue "$UNCONFIG_COLUMN"`;;
			'NO CONFIGURE') UNCONFIG_COLUMN=`print_red "$UNCONFIG_COLUMN"`;;
			*) UNCONFIG_COLUMN=`print_yellow "$UNCONFIG_COLUMN"`
		esac
		printf '%-31s%-31s%-31s%-31s%-31s%-31s\n' "$PKG_COLUMN" "$PLATFORM_COLUMN" "$INSTALL_COLUMN" "$UNINSTALL_COLUMN" "$CONFIG_COLUMN" "$UNCONFIG_COLUMN"
	done
	printf '\n'
	exit 0
}

execute_script() (
	DEFAULT_OR_CUSTOM=
	SCRIPT=
	SCRIPT_ARGS=
	SCRIPT_NAME=
	NEXT_OPERATION=

	case "$1" in
		pre*|post*|custom_*) DEFAULT_OR_CUSTOM='custom';;
		*) DEFAULT_OR_CUSTOM='default';;
	esac

	case "$1" in
		custom_*) SCRIPT_NAME="${1#custom_}";;
		default_*) SCRIPT_NAME="${1#default_}";;
		*) SCRIPT_NAME="$1";;
	esac

	case "$1" in
		default_*) SCRIPT="$CONFMAN_TASK" && SCRIPT_ARGS="$SCRIPT_NAME";;
		*) SCRIPT="$PKG_DIR/$SCRIPT_NAME";;
	esac

	case "$SCRIPT_NAME" in
		pre*) NEXT_OPERATION="${SCRIPT_NAME#pre}";;
		install|configure) NEXT_OPERATION="post${SCRIPT_NAME}";;
		*) NEXT_OPERATION=;;
	esac

	"$CONFMAN_LOG" info "Performing $DEFAULT_OR_CUSTOM $(print_blue "$SCRIPT_NAME") for $(print_blue "$PKG")"

	verify_execute_permission "$SCRIPT"

	# Invoke the specified script as a command to enable execution by a different interpreter or as a standalone executable
	if "$SCRIPT" $SCRIPT_ARGS; then
		"$CONFMAN_LOG" success "SUCCESSFULLY performed $DEFAULT_OR_CUSTOM \"$SCRIPT_NAME\" for \"$PKG\"\n"
	else
		"$CONFMAN_LOG" error "An error occured during $DEFAULT_OR_CUSTOM \"$SCRIPT_NAME\" for \"$PKG\""
		if [ "$NEXT_OPERATION" ]; then "$CONFMAN_LOG" error "Skipping \"$NEXT_OPERATION\" for \"$PKG\""; fi
		printf '\n'
	fi
)

dispatch_operations() {
	TARGET_PKGS=

	# Update/sync back-end package manager repositories. Set options and environment variables
	case "$1" in
		install | uninstall) TARGET_PKGS="$INSTALL_PKGS" && "$CONFMAN_TASK" update;;
		configure | deconfigure) TARGET_PKGS="$SETUP_PKGS";;
		*) "$CONFMAN_LOG" error "unrecognized argument value passed to function 'dispatch_operations': $1" && return 1;;
	esac

	if [ -z "$TARGET_PKGS" ]; then
		"$CONFMAN_LOG" warning "No package available for $1.. Done."
		return 0
	fi

	"$CONFMAN_LOG" info "Packages selected for $(print_blue "$1"):\n$TARGET_PKGS\n"
	prompt_continuation_or_exit

	case "$CONFMAN_PROMPT" in
		0) INPUT_DEVICE='/dev/null';;
		*) INPUT_DEVICE='/dev/tty';;
	esac

	printf '%s\n' "$TARGET_PKGS" | while read -r PKG; do
		PKG_DIR="$CONFMAN_REPO/$PKG"
		case "$1" in
			install | configure)
				if [ -f "$PKG_DIR/pre$1" ]; then execute_script "pre$1"; fi
				if [ -f "$PKG_DIR/$1" ]; then
					execute_script "custom_$1"
				else
					execute_script "default_$1"
				fi
				if [ -f "$PKG_DIR/post$1" ]; then execute_script "post$1"; fi
			;;
			uninstall | deconfigure)
				if [ -f "$PKG_DIR/$1" ]; then
					execute_script "custom_$1"
				else
					execute_script "default_$1"
				fi
			;;
		esac < "$INPUT_DEVICE"
	done
}

