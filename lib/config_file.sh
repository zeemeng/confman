#!/usr/bin/env sh

validate_kv_pair () {
	if printf '%s\n' "$1" | grep -q '^[[:space:]]*='; then
		confman -L error "invalid key-value pair in file '$2', missing key in line:\n$1\n"
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
	#############
	# echo "---PLATFORM_LABEL--->>>$1" ### debug
	#############
	uname -s | grep -i -q "$1"
}

assign_valid_section_pkgconf () {
	#############
	# printf '\n%s\n' "$1" ### debug
	#############
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
		*) confman -L error "unrecognized section in file '$2':\n$1\n"; return 1 ;;
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
			'') confman -L error "line without a section in file '$1':\n$1\n"; return 1 ;;
			# \[package.dependencies\]) ;;
			\[package\])
				case "$CONF_KEY" in
					managers) eval_kv_managers ;;
					platforms) eval_kv_platforms ;;
					noinstall) eval_kv_noinstall ;;
					noconfigure) eval_kv_noconfigure ;;
				esac
				;;
			# \[platform.*.dependencies\]) ;;
			\[platform.*\])
				case "$CONF_KEY" in
					noinstall) eval_kv_noinstall ;;
					noconfigure) eval_kv_noconfigure ;;
				esac
				;;
			# \[manager.$CONFMAN_MGR.dependencies\]) ;;
			\[manager.$CONFMAN_MGR\])
				case "$CONF_KEY" in
					noinstall) eval_kv_noinstall ;;
					noconfigure) eval_kv_noconfigure ;;
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
			'') confman -L error "line without a section in file '$1':\n$1\n"; return 1 ;;
			\[package\])
				case "$CONF_KEY" in (name) eval_kv_name; esac
				;;
			\[platform.*\])
				case "$CONF_KEY" in (name) eval_kv_name; esac
				;;
			\[manager.$CONFMAN_MGR\])
				case "$CONF_KEY" in
					name) eval_kv_name ;;
					mgr_opts) eval_kv_mgr_opts ;;
				esac
				;;
		esac
	done <<-EOF
		$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#.*/d' "$1")
	EOF
}

assign_valid_section_confmanconf () {
	#############
	# printf '\n%s\n' "$1" ### debug
	#############
	case "$1" in
		\[list.*\] | \[manager.*\]) ;;
		*) confman -L error "unrecognized section in file '$2':\n$1\n"; return 1 ;;
	esac

	SECTION="$1"
}

evaluate_confmanconf () {
	SECTION=''
	while read -r LINE; do
		case "$LINE" in (\[*\])
			assign_valid_section_confmanconf "$LINE" "$1"
			safe_read_next_line 'LINE'
		esac

		validate_kv_pair "$LINE" "$1"
		CONF_KEY="$(parse_conf_key "$LINE")"
		CONF_VALUE="$(parse_conf_value "$LINE")"

		case "$SECTION" in
			'') confman -L error "line without a section in file '$1':\n$1\n"; return 1 ;;
			\[list.*\]) ;;
			\[manager.*\]) ;;
		esac
	done <<-EOF
		$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#.*/d' "$1")
	EOF
}

# Operations time evaluations
eval_kv_name () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug
#############
	PKG="$CONF_VALUE"
}

eval_kv_mgr_opts () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug
#############
	CONFMAN_MGR_OPTS="$CONF_VALUE"
}

# Package selection time evaluations
eval_kv_managers () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug
#############
	case "$CONF_VALUE" in (*${CONFMAN_MGR}*) return 0; esac
	unset -v DO_INSTALL DO_CONFIGURE
}

eval_kv_platforms () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug
#############
	for PATTERN in $CONF_VALUE; do uname -s | grep -i -q "$PATTERN" && return 0; done
	unset -v DO_INSTALL DO_CONFIGURE
}

eval_kv_noinstall () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug
#############
	unset -v DO_INSTALL
}

eval_kv_noconfigure () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug
#############
	unset -v DO_CONFIGURE
}

