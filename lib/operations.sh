#!/usr/bin/env sh

unset -v REQUESTED_PKGS INSTALL_PKGS SETUP_PKGS SKIP_PKGS PKG_DIR

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

find_data_path () {
	if [ -d "$CONFMAN_ROOT/packages" ]; then printf "$CONFMAN_ROOT"; return 0; fi
	if [ -d "$HOME/.confman" ]; then printf "$HOME/.confman"; return 0; fi
	if [ "$XDG_CONFIG_HOME" ] && [ -d "$XDG_CONFIG_HOME/confman" ]; then printf "$XDG_CONFIG_HOME/confman"; return 0; fi
	if [ -d "$HOME/.config/confman" ]; then printf "$HOME/.config/confman"; return 0; fi
}

warn_about_skipped_packages() {
	if [ -z "$SKIP_PKGS" ]; then return; fi

	confman_log warning "Skipping the following package(s) as they do not support the requested operation(s) on the current platform:"
	printf "$SKIP_PKGS\n\n"
}

# Depends on pre-defined variables: CONFMAN_REPO, PKG, REQUESTED_PKGS, INSTALL_PKGS, SETUP_PKGS, SKIP_PKGS
append_to_pkg_lists() {
	PKG_DIR="$CONFMAN_REPO/$PKG"

	# Check if PKG contains any non-whitespace character. If it does, continue, otherwise return
	if ! echo "$PKG" | grep -q "[^[:space:]]"; then return; fi

	# Skip the meta package 'default' which holds the default PKG scripts
	if [ "default" = "$PKG" ]; then return; fi

	# Append to the list of requested pkgs
	REQUESTED_PKGS="${REQUESTED_PKGS}${PKG}"$'\n'

	# If any line in the "$PKG_DIR/platform" file is a case insensitive BRE matching any part
	# of the output of `uname -s`, continue processing, else return.
	if [ -f "$PKG_DIR/platform" ] && ! is_platform_compatible "$PKG_DIR/platform"; then
		SKIP_PKGS="${SKIP_PKGS}${PKG}"$'\n'
		return
	fi

	if [ -f "$PKG_DIR/noinstall" ] && [ -f "$PKG_DIR/noconfigure" ]; then
		SKIP_PKGS="${SKIP_PKGS}${PKG}"$'\n'
		return
	fi

	if [ -f "$PKG_DIR/noinstall" ]; then
		SETUP_PKGS="${SETUP_PKGS}${PKG}"$'\n'
		return
	fi

	if [ -f "$PKG_DIR/noconfigure" ]; then
		INSTALL_PKGS="${INSTALL_PKGS}${PKG}"$'\n'
		return
	fi

	if [ -d "$PKG_DIR" ]; then
		SETUP_PKGS="${SETUP_PKGS}${PKG}"$'\n'
		INSTALL_PKGS="${INSTALL_PKGS}${PKG}"$'\n'
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
		confman_log warning "Cannot read package list file. Defaulting to select all packages from repository."
		prompt_continuation_or_exit
		unset f;
	fi

	# If no operand and no package-list file is specified, select all packages from the target package repository
	if [ "$#" -eq 0 ] && [ ! "$PKG_FILE" ]; then
		while read -r PKG; do
			if [ -d "$CONFMAN_REPO/$PKG" ]; then append_to_pkg_lists; fi
		done <<-EOF
		$(ls -1AL "$CONFMAN_REPO")
		EOF
	fi

	# Sort and remove duplicate items in PKG lists
	REQUESTED_PKGS="$(printf "$REQUESTED_PKGS" | sort -u)"
	INSTALL_PKGS="$(printf "$INSTALL_PKGS" | sort -u)"
	SETUP_PKGS="$(printf "$SETUP_PKGS" | sort -u)"
	SKIP_PKGS="$(printf "$SKIP_PKGS" | sort -u)"
}

print_selected_packages() {
	unset -v PKG_COLUMN PLATFORM_COLUMN INSTALL_COLUMN UNINSTALL_COLUMN CONFIG_COLUMN UNCONFIG_COLUMN

	# Print header
	printf "%-31s%-31s%-31s%-31s%-31s%-31s\n" "`print_blue Package Name`" "`print_blue Platform`" "`print_blue Install`" "`print_blue Uninstall`" "`print_blue Configure`" "`print_blue Unconfigure`"
	printf "===============================================================================================================\n"

	printf '%s\n' "$REQUESTED_PKGS" | while read -r PKG; do
		PKG_DIR="$CONFMAN_REPO/$PKG"

		# "Package Name" column
		PKG_COLUMN="$(confman_log hl_blue "$PKG")"

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
}

dispatch_d_task () {
	case "$#" in
		0) ;;
		1) PKG="$1";;
		*) confman_log error 'too many operands'; print_usage_exit;;
	esac
	case "$D_OPTARG" in
		update|install|uninstall|configure|unconfigure) execute_task "$D_OPTARG";;
		*) confman_log error "unrecognized argument value passed to option '-D': $1"; print_usage_exit;;
	esac
	exit 0
}

execute_task() (
	unset -v DEFAULT_OR_CUSTOM SCRIPT SCRIPT_NAME

	case "$1" in
		custom_*) SCRIPT_NAME="${1#custom_}";;
		*) SCRIPT_NAME="$1";;
	esac

	case "$1" in
		pre*|post*|custom_*)
			DEFAULT_OR_CUSTOM='custom'
			SCRIPT="$CONFMAN_REPO/$PKG/$SCRIPT_NAME";;
		configure|unconfigure)
			DEFAULT_OR_CUSTOM='default'
			SCRIPT="$CONFMAN_LIB_PATH/$SCRIPT_NAME";;
		*)
			DEFAULT_OR_CUSTOM='default'
			SCRIPT="$CONFMAN_LIB_PATH/mgr/$CONFMAN_MGR/$SCRIPT_NAME";;
	esac

	if [ "$SCRIPT_NAME" = "update" ]; then
		fix_permission_execute "$SCRIPT"
		return;
	fi

	if [ ! "$D_OPTARG" ]; then
		confman_log info "Performing $DEFAULT_OR_CUSTOM $(print_blue "$SCRIPT_NAME") for $(print_blue "$PKG")"
	fi

	if fix_permission_execute "$SCRIPT"; then
		confman_log success "SUCCESSFULLY performed $DEFAULT_OR_CUSTOM \"$SCRIPT_NAME\" for \"$PKG\"\n"
	else
		confman_log error "An error occured during $DEFAULT_OR_CUSTOM \"$SCRIPT_NAME\" for \"$PKG\"\n"
	fi
)

dispatch_operations() {
	unset -v TARGET_PKGS INPUT_DEVICE PKG_DIR

	# Update/sync back-end package manager repositories. Set options and environment variables
	case "$1" in
		install | uninstall) TARGET_PKGS="$INSTALL_PKGS" && execute_task update;;
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
				if [ -f "$PKG_DIR/pre$1" ]; then execute_task "pre$1"; fi
				if [ -f "$PKG_DIR/$1" ]; then
					execute_task "custom_$1"
				else
					execute_task "$1"
				fi
				if [ -f "$PKG_DIR/post$1" ]; then execute_task "post$1"; fi
			;;
			uninstall | unconfigure)
				if [ -f "$PKG_DIR/$1" ]; then
					execute_task "custom_$1"
				else
					execute_task "$1"
				fi
			;;
		esac < "$INPUT_DEVICE"
	done
}

