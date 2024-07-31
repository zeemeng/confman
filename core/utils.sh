#!/usr/bin/env sh

print_exit_usage() {
	cat <<- EOF
	USAGE:
	setdots [-iIs] [-f package_list] [-m manager] [-p n] [package ...]
	setdots [-uUr] [-f package_list] [-m manager] [-p n] [package ...]
	setdots [-l] [-f package_list] [package ...]
	setdots [-vhH] 

	EOF
	exit 1
}

print_exit_version() {
	echo "setdots v0.1"
	exit 0
}

show_manpage_exit() {
	man "$EXEC_DIR/manpage/roff/setdots.1"
	exit 0
}

print_exit_invalid_options_combination() {
	echo "ERROR: Options -i, -I, and -s cannot be used in conjunction with options -u, -U, or -r" >&2
	exit 1
}

append_to_selected_pkgs() {
	# Expecting pre-defined variables: PKG_REPO, PKG, SELECTED_PKGS, NEW_LINE

	# Check if PKG contains any non-whitespace character. If it does, continue, otherwise return
	echo "$PKG" | grep -q "[^[:space:]]" || return

	# Add PKG to SELECTED_PKGS on a new line, suffixed with ":nis"
	if [ -f "$PKG_REPO/$PKG/noinstall" ] && [ -f "$PKG_REPO/$PKG/nosetup" ]; then
		SELECTED_PKGS="${SELECTED_PKGS}${NEW_LINE}${PKG}:nis"
		return
	fi

	# Add PKG to SELECTED_PKGS on a new line, suffixed with ":ni"
	if [ -f "$PKG_REPO/$PKG/noinstall" ]; then
		SELECTED_PKGS="${SELECTED_PKGS}${NEW_LINE}${PKG}:ni"
		return
	fi

	# Add PKG to SELECTED_PKGS on a new line, suffixed with ":ns"
	if [ -f "$PKG_REPO/$PKG/nosetup" ]; then
		SELECTED_PKGS="${SELECTED_PKGS}${NEW_LINE}${PKG}:ns"
		return
	fi

	# Add PKG to SELECTED_PKGS on a new line, suffixed with ":is"
	if [ -d "$PKG_REPO/$PKG" ]; then
		SELECTED_PKGS="${SELECTED_PKGS}${NEW_LINE}${PKG}:is"
		return
	fi
}

print_cannot_read_package_list_file() {
	echo "ERROR >>> Cannot read package list file. Defaulting to select all packages from repository." >&2
}

read_selected_packages() {
	SELECTED_PKGS=""; NEW_LINE="
"
	# Select packages from operands
	for PKG in "$@"; do append_to_selected_pkgs; done

	# If specified file exists and can be read, select packages from file line-by-line
	if [ -f "$f" ] && [ -r "$f" ]; then
		while read PKG; do append_to_selected_pkgs; done < "$f"

	# Specified file exists, but cannot be read
	elif [ "$f" ]; then
		print_cannot_read_package_list_file;
	fi

	# If no operand and no package-list file is specified, select all packages from the target package repository
	if [ "$#" -eq 0 ] && [ ! "$f" ]; then
		while read PKG; do
			append_to_selected_pkgs
		done <<-EOF
		$(ls -1A "$PKG_REPO")
		EOF
	fi

	# Sort and remove duplicate items in SELECTED_PKGS
	SELECTED_PKGS="$(echo "$SELECTED_PKGS" | sort -u)"

	# DEBUG
	# echo ">$SELECTED_PKGS<";
}

print_exit_selected_packages() {
	NO_SUFFIX="$(echo "$SELECTED_PKGS" | sed -n 's/:..$//p; s/:nis$//p')"

	# Print header
	printf "%-20s%-20s%-20s%-20s%-20s\n" "Package Name" "Install" "Uninstall" "Configure" "RM Config"
	printf "=========================================================================================\n"

	printf "$NO_SUFFIX\n" | while read PKG; do
		# "Package Name" column
		printf "%-20s" "$PKG"

		# "Install" and "Uninstall" columns
		INSTALL_COLUMN=""; UNINSTALL_COLUMN=""; # Reset vars for each iteration
		if [ -f "$PKG_REPO/$PKG/noinstall" ]; then
			INSTALL_COLUMN="NO INSTALL"
		else
			if [ -f "$PKG_REPO/$PKG/install" ]; then INSTALL_COLUMN="CUSTOM"; else INSTALL_COLUMN="DEFAULT"; fi
			if [ -f "$PKG_REPO/$PKG/preinstall" ]; then INSTALL_COLUMN="${INSTALL_COLUMN}, PRE"; fi
			if [ -f "$PKG_REPO/$PKG/postinstall" ]; then INSTALL_COLUMN="${INSTALL_COLUMN}, POST"; fi

			if [ -f "$PKG_REPO/$PKG/uninstall" ]; then UNINSTALL_COLUMN="CUSTOM"; else UNINSTALL_COLUMN="DEFAULT"; fi
		fi
		printf "%-20s%-20s" "$INSTALL_COLUMN" "$UNINSTALL_COLUMN"

		# "Configure" and "RM Config" column
		CONFIG_COLUMN="";RM_CONFIG_COLUMN=""; # Reset vars for each iteration
		if [ -f "$PKG_REPO/$PKG/nosetup" ]; then
			CONFIG_COLUMN="NO SETUP"
		else
			if [ -f "$PKG_REPO/$PKG/setup" ]; then CONFIG_COLUMN="CUSTOM"; else CONFIG_COLUMN="DEFAULT"; fi
			if [ -f "$PKG_REPO/$PKG/presetup" ]; then CONFIG_COLUMN="${CONFIG_COLUMN}, PRE"; fi
			if [ -f "$PKG_REPO/$PKG/postsetup" ]; then CONFIG_COLUMN="${CONFIG_COLUMN}, POST"; fi

			if [ -f "$PKG_REPO/$PKG/unset" ]; then RM_CONFIG_COLUMN="CUSTOM"; else RM_CONFIG_COLUMN="DEFAULT"; fi
		fi
		printf "%-20s%-20s" "$CONFIG_COLUMN" "$RM_CONFIG_COLUMN"

		printf "\n"
	done
}

execute_custom_script() {
	PKG="$1"
	SCRIPT="$2"
	SCRIPT_NAME="$(basename "$SCRIPT")"
	NEXT_OPERATION="$3"

	echo "\nSETDOTS >>> Running custom \"$SCRIPT_NAME\" script for \"$PKG\""

	if [ ! -x "$SCRIPT" ]; then
		echo "\nSETDOTS >>> Adding execute permission to \"$SCRIPT_NAME\" script for \"$PKG\""
		chmod +x "$SCRIPT"
	fi

	# Invoke the specified custom script as a command to enable execution by a different interpreter or as a standalone executable
	if "$SCRIPT"; then
		echo "SETDOTS >>> Custom \"$SCRIPT_NAME\" script DONE for \"$PKG\""
	else
		echo "ERROR >>> Error in custom \"$SCRIPT_NAME\" script for \"$PKG\"" >&2
		if [ "$NEXT_OPERATION" ]; then echo "ERROR >>> Skipping \"$NEXT_OPERATION\" for \"$PKG\"" >&2; fi
	fi
}

execute_default_script() {
	PKG="$1"
	SCRIPT="$2"
	SCRIPT_NAME="$(basename "$SCRIPT")"
	NEXT_OPERATION="$3"

 	echo "\nSETDOTS >>> Running default \"$SCRIPT_NAME\" operation for \"$PKG\""
 	
	# Dot source the specified default script to have access to previously defined variables
 	if . "$SCRIPT"; then
 		echo "SETDOTS >>> Default \"$SCRIPT_NAME\" operation DONE for \"$PKG\""
 	else
 		echo "ERROR >>> Error in default \"$SCRIPT_NAME\" operation for \"$PKG\"" >&2
		if [ "$NEXT_OPERATION" ]; then echo "ERROR >>> Skipping \"$NEXT_OPERATION\" for \"$PKG\"" >&2; fi
 	fi
}

prompt_confirmation() {
	printf 'Are you sure you want to continue? (y)es / (n)o: '
	read RESPONSE
	echo "$RESPONSE" | grep -q "^[Yy]" && return 0
	echo 'Aborting..' && return 1
}

install_selected_packages() {
	# Find packages to be installed among SELECTED_PKGS
	INSTALL_PKGS="$(echo "$SELECTED_PKGS" | sed -n 's/:is$//p; s/:ns$//p')"
	if [ -z "$INSTALL_PKGS" ]; then return; fi # If found none, return early
	printf "\nSETDOTS >>> Packages to be installed:\n$INSTALL_PKGS\n\n"

	# If SETDOTS_PROMPT is level 1 or level 2
	if [ "$SETDOTS_PROMPT" -ge 1 ]; then prompt_confirmation || exit 1; fi

	# Update/sync back-end package manager repositories. Set options and environment variables
	init_pkg_manager

	echo "$INSTALL_PKGS" | while read PKG; do
		PREINSTALL="$PKG_REPO/$PKG/preinstall" 
		CUSTOM_INSTALL="$PKG_REPO/$PKG/install"
		DEFAULT_INSTALL="$EXEC_DIR/core/default/install"
		POSTINSTALL="$PKG_REPO/$PKG/postinstall"

		if [ -f "$PREINSTALL" ]; then execute_custom_script "$PKG" "$PREINSTALL" "install" < /dev/tty; fi
		if [ -f "$CUSTOM_INSTALL" ]; then
			execute_custom_script "$PKG" "$CUSTOM_INSTALL" "postinstall" < /dev/tty
		else
			execute_default_script "$PKG" "$DEFAULT_INSTALL" "postinstall" < /dev/tty
		fi
		if [ -f "$POSTINSTALL" ]; then execute_custom_script "$PKG" "$POSTINSTALL" < /dev/tty; fi
	done
}

configure_selected_packages() {
	# Find packages to be configured among SELECTED_PKGS
	SETUP_PKGS="$(echo "$SELECTED_PKGS" | sed -n 's/:is$//p; s/:ni$//p')"
	if [ -z "$SETUP_PKGS" ]; then return; fi # If found none, return early
	printf "\nSETDOTS >>> Packages to be configured:\n$SETUP_PKGS\n\n"

	# If SETDOTS_PROMPT is level 1 or level 2
	if [ "$SETDOTS_PROMPT" -ge 1 ]; then prompt_confirmation || exit 1; fi

	echo "$SETUP_PKGS" | while read PKG; do
		PRESETUP="$PKG_REPO/$PKG/presetup"
		CUSTOM_SETUP="$PKG_REPO/$PKG/setup"
		DEFAULT_SETUP="$EXEC_DIR/core/default/setup"
		POSTSETUP="$PKG_REPO/$PKG/postsetup"

		if [ -f "$PRESETUP" ]; then execute_custom_script "$PKG" "$PRESETUP" "setup" < /dev/tty; fi
		if [ -f "$CUSTOM_SETUP" ]; then
			execute_custom_script "$PKG" "$CUSTOM_SETUP" "postsetup" < /dev/tty
		else
			execute_default_script "$PKG" "$DEFAULT_SETUP" "postsetup" < /dev/tty
		fi
		if [ -f "$POSTSETUP" ]; then execute_custom_script "$PKG" "$POSTSETUP" < /dev/tty; fi
	done
}

uninstall_selected_packages() {
	# Find packages to be uninstalled among SELECTED_PKGS
	UNINSTALL_PKGS="$(echo "$SELECTED_PKGS" | sed -n 's/:is$//p; s/:ns$//p')"
	if [ -z "$UNINSTALL_PKGS" ]; then return; fi # If found none, return early
	printf "\nSETDOTS >>> Packages to be uninstalled:\n$UNINSTALL_PKGS\n\n"

	# If SETDOTS_PROMPT is level 1 or level 2
	if [ "$SETDOTS_PROMPT" -ge 1 ]; then prompt_confirmation || exit 1; fi

	# Update/sync back-end package manager repositories. Set options and environment variables
	init_pkg_manager

	echo "$UNINSTALL_PKGS" | while read PKG; do
		CUSTOM_UNINSTALL="$PKG_REPO/$PKG/uninstall"
		DEFAULT_UNINSTALL="$EXEC_DIR/core/default/uninstall"

		if [ -f "$CUSTOM_UNINSTALL" ]; then
			execute_custom_script "$PKG" "$CUSTOM_UNINSTALL" < /dev/tty
		else
			execute_default_script "$PKG" "$DEFAULT_UNINSTALL" < /dev/tty
		fi
	done
}

remove_configuration_for_selected_packages() {
	# Find packages for which to remove configuration among SELECTED_PKGS
	UNSET_PKGS="$(echo "$SELECTED_PKGS" | sed -n 's/:is$//p; s/:ni$//p')"
	if [ -z "$UNSET_PKGS" ]; then return; fi # If found none, return early
	printf "\nSETDOTS >>> Removing configuration for following packages:\n$UNSET_PKGS\n\n"

	# If SETDOTS_PROMPT is level 1 or level 2
	if [ "$SETDOTS_PROMPT" -ge 1 ]; then prompt_confirmation || exit 1; fi

	echo "$UNSET_PKGS" | while read PKG; do
		CUSTOM_UNSET="$PKG_REPO/$PKG/unset"
		DEFAULT_UNSET="$EXEC_DIR/core/default/unset"

		if [ -f "$CUSTOM_UNSET" ]; then
			execute_custom_script "$PKG" "$CUSTOM_UNSET" < /dev/tty
		else
			execute_default_script "$PKG" "$DEFAULT_UNSET" < /dev/tty
		fi
	done
}

