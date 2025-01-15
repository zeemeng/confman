#!/usr/bin/env sh

# . ./colors.sh ### debug
# . ./utils.sh ### debug

validate_kv_pair () {
	if printf '%s\n' "$1" | grep -q '^[[:space:]]*='; then
		confman_log error "invalid key-value pair in file '$2', missing key in line:\n$1\n"
		return 1
	fi
}

parse_conf_key () { printf '%s\n' "$1" | sed -E -e 's/^[[:space:]]//' -e 's/[[:space:]]*=.*$//'; }

parse_conf_value () { printf '%s\n' "$1" | sed -E -e 's/^[^=]*//' -e 's/=[[:space:]]*//'; }

safe_read_next_line () {
	read -r "$1" || case "$?" in
		1) return 0 ;;
		*) return "$?" ;;
	esac
}

system_matches_platform () {
	set -- "$(printf '%s\n' "$1" | sed -E -e 's/^\[platform\.//' -e 's/(\.dependencies)?\]$//')"
# 	echo "---PLATFORM_LABEL--->>>$1" ### debug
	uname -s | grep -i -q "$1"
}

assign_valid_section_pkgconf () {
# 	printf '\n%s\n' "$1" ### debug
	case "$1" in
		\[package*\] | \[manager.*\]) ;;
		\[platform.*\])
			if ! system_matches_platform "$1"; then while read -r LINE; do
				case "$LINE" in (\[*\])
					assign_valid_section_pkgconf "$LINE" "$2"
					return 0
				esac
			done; fi
			;;
		*) confman_log error "unrecognized section in file '$2':\n$1\n"; return 1 ;;
	esac
	SECTION="$1"
}

evaluate_pkgconf_selection () {
	SECTION=''
	while read -r LINE; do
		case "$LINE" in (\[*\])
			assign_valid_section_pkgconf "$LINE" "$1"
			safe_read_next_line 'LINE'
		esac

		validate_kv_pair "$LINE" "$1"
		CONF_KEY="$(parse_conf_key "$LINE")"
		CONF_VALUE="$(parse_conf_value "$LINE")"

		case "$SECTION" in
			'') confman_log error "line without a section in file '$1':\n$1\n"; return 1 ;;
			# \[package.dependencies\]) ;;
			\[package\])
				case "$CONF_KEY" in
					managers) eval_key_managers ;;
					platforms) eval_key_platforms ;;
					noinstall) eval_key_noinstall ;;
					noconfigure) eval_key_noconfigure ;;
				esac
				;;
			# \[platform.*.dependencies\]) ;;
			\[platform.*\])
				case "$CONF_KEY" in
					noinstall) eval_key_noinstall ;;
					noconfigure) eval_key_noconfigure ;;
				esac
				;;
			# \[manager.$CONFMAN_MGR.dependencies\]) ;;
			\[manager.$CONFMAN_MGR\])
				case "$CONF_KEY" in
					noinstall) eval_key_noinstall ;;
					noconfigure) eval_key_noconfigure ;;
				esac
				;;
		esac
	done <<-EOF
		$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#.*/d' "$1")
	EOF
}

evaluate_pkgconf_operation () {
	SECTION=''
	while read -r LINE; do
		case "$LINE" in (\[*\])
			assign_valid_section_pkgconf "$LINE" "$1"
			safe_read_next_line 'LINE'
		esac

		validate_kv_pair "$LINE" "$1"
		CONF_KEY="$(parse_conf_key "$LINE")"
		CONF_VALUE="$(parse_conf_value "$LINE")"

		case "$SECTION" in
			'') confman_log error "line without a section in file '$1':\n$1\n"; return 1 ;;
			\[package\])
				case "$CONF_KEY" in (name) eval_key_name; esac
				;;
			\[platform.*\])
				case "$CONF_KEY" in (name) eval_key_name; esac
				;;
			\[manager.$CONFMAN_MGR\])
				case "$CONF_KEY" in
					name) eval_key_name ;;
					mgr_opts) eval_key_mgr_opts ;;
				esac
				;;
		esac
	done <<-EOF
		$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#.*/d' "$1")
	EOF
}

assign_valid_section_confmanconf () {
# 	printf '\n%s\n' "$1" ### debug
	case "$1" in
		\[list.*\]) LIST_NAME="$(printf '%s\n' "$1" | sed -E 's/^\[list\.(.*)\]$/\1/')" ;;
		\[manager.*\]) MGR_NAME="$(printf '%s\n' "$1" | sed -E 's/^\[manager\.(.*)\]$/\1/')" ;;
		*) confman_log error "unrecognized section in file '$2':\n$1\n"; return 1 ;;
	esac
	SECTION="$1"
}

apply_matched_manager_section () { :; }

evaluate_confmanconf () {
	SECTION=''; DUPLICATE_PLATFORM_KEY=''; MGR_NAME=''; LIST_NAME=''
	while read -r LINE; do
		case "$LINE" in (\[*\])
			apply_matched_manager_section
			assign_valid_section_confmanconf "$LINE" "$1"
			safe_read_next_line 'LINE'
		esac

		validate_kv_pair "$LINE" "$1"
		CONF_KEY="$(parse_conf_key "$LINE")"
		CONF_VALUE="$(parse_conf_value "$LINE")"

		case "$SECTION" in
			'') confman_log error "line without a section in file '$1':\n$1\n"; return 1 ;;
			\[list.*\])
				case "$CONF_KEY" in
					packages) eval_key_packages ;;
					include) eval_key_include ;;
				esac
				;;
			\[manager.*\])
				case "$CONF_KEY" in
					platforms) eval_confmanconf_key_platforms "$CONF_VALUE" "$MGR_NAME" ;;
					mgr_prompt_0) eval_key_mgr_prompt ;;
					mgr_prompt_1) eval_key_mgr_prompt ;;
					mgr_prompt_2) eval_key_mgr_prompt ;;
					mgr_opts) eval_key_mgr_opts ;;
					install) eval_key_install ;;
					uninstall) eval_key_uninstall ;;
					update) eval_key_update ;;
				esac
				;;
		esac
	done <<-EOF
		$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#.*/d' "$1")
	EOF
}

eval_confmanconf_key_platforms () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	if printf '%s\n' "$DUPLICATE_PLATFORM_KEY" | grep -i -q -F "$2"; then
		confman_log error "duplicate 'platform' key detected for manager '$2':\n$LINE\n"
		return 1
	else
		DUPLICATE_PLATFORM_KEY="$(printf '%s\n%s' "$DUPLICATE_PLATFORM_KEY" "$2")"
	fi

	[ "$CONFMAN_MGR" ] || for PATTERN in $1; do
#		if uname -s | grep -i -q "$PATTERN" && command -v "$2" >/dev/null; then echo "CONFMAN_MGR>>>$2"; fi ### debug
		if uname -s | grep -i -q "$PATTERN" && command -v "$2" >/dev/null; then CONFMAN_MGR="$2"; break; fi
	done
}

eval_key_packages () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	:
}

eval_key_include () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	:
}

eval_key_mgr_prompt () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	:
}

eval_key_install () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	:
}

eval_key_uninstall () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	:
}

eval_key_update () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	:
}

# Operations time evaluations
eval_key_name () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	PKG="$CONF_VALUE"
}

eval_key_mgr_opts () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	CONFMAN_MGR_OPTS="$CONF_VALUE"
}

# Package selection time evaluations
eval_key_managers () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	case "$CONF_VALUE" in (*${CONFMAN_MGR}*) return 0; esac
	unset -v DO_INSTALL DO_CONFIGURE
}

eval_key_platforms () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	for PATTERN in $CONF_VALUE; do
		if uname -s | grep -i -q "$PATTERN"; then return 0; fi
	done
	unset -v DO_INSTALL DO_CONFIGURE
}

eval_key_noinstall () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	unset -v DO_INSTALL
}

eval_key_noconfigure () {
# 	echo "$CONF_KEY>>>$CONF_VALUE" ### debug
	unset -v DO_CONFIGURE
}

