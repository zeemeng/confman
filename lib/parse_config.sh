#!/usr/bin/env sh

parse_section () {
	PKGCONF="$CONFMAN_REPO/$PKG/pkg.conf"
	PKGCONF=$1
	while read -r SECTION; do
		EOF=0; while [ 0 = "$EOF" ]; do
			case "$SECTION" in
				"[package*]" | "[platform.*]" | "[manager.*]") ;;
				"[*]") confman -L error "unrecognized section in file '$PKGCONF':\n$SECTION\n"; return 1;;
				*) confman -L error "line without a section in file '$PKGCONF':\n$SECTION\n"; return 1;;
			esac

			parse_kvpairs
		done
	done <<-EOF
		$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#.*/d' "$PKGCONF")
	EOF
}

parse_kvpairs () {
	unset -v SKIP_SECTION
	case "$SECTION" in ("[platform.*]")
		PLATFORM_LABEL="$(printf '%s\n' "$SECTION" | sed -E -e 's/^\[platform\.//' -e 's/(\.dependencies|\.environment)?\]$//')"
		uname -s | grep -i -q "$PLATFORM_LABEL" || SKIP_SECTION=1
### debug ###
# echo "---PLATFORM_LABEL--->>>$PLATFORM_LABEL"
	esac
### debug ###
# echo "$SECTION"


	while read -r LINE; do
		# Hit the next section's header; return control to outer while loop
		case "$LINE" in ("[*]")
			SECTION="$LINE"
			return 0
			;;
		esac

		# KV-pair syntax validation
		if printf '%s\n' "$LINE" | grep -q '^[[:space:]]*='; then
			confman -L error "invalid key-value pair in file '$PKGCONF', missing key in line:\n$LINE\n"
			return 1
		fi

		CONF_KEY="$(printf '%s\n' "$LINE" | sed -E -e 's/^[[:space:]]//' -e 's/[[:space:]]*=.*$//')"
		CONF_VALUE="$(printf '%s\n' "$LINE" | sed -E -e 's/^[^=]*//' -e 's/=[[:space:]]*//')"

		[ ! "$SKIP_SECTION" ] && case "$SECTION" in
			# "[package.dependencies]") ;;
			# "[package.environment]") ;;
			"[package]")
				eval_kv_name ||
				eval_kv_managers ||
				eval_kv_platforms ||
				eval_kv_noinstall ||
				eval_kv_noconfigure ||
				unknown_key_error
				;;
			# "[platform.*.dependencies]") ;;
			# "[platform.*.environment]") ;;
			"[platform.*]")
				eval_kv_package ||
				eval_kv_noinstall ||
				eval_kv_noconfigure ||
				unknown_key_error
				;;
			# "[manager.$CONFMAN_MGR.dependencies]") ;;
			# "[manager.$CONFMAN_MGR.environment]") ;;
			"[manager.$CONFMAN_MGR]")
				eval_kv_package ||
				eval_kv_noinstall ||
				eval_kv_noconfigure ||
				eval_kv_mgr_opts ||
				unknown_key_error
				;;
			"[manager.platforms]") ;;
			"[manager.operations]") ;;
		esac
	done
	EOF=1
}

# Operations time evaluations
eval_kv_name () {
	if [ "name" = "$CONF_KEY" ]; then
		return 0
	fi
	return 1
}

eval_kv_package () {
	if [ "package" = "$CONF_KEY" ]; then
		return 0
	fi
	return 1
}

eval_kv_mgr_opts () {
	if [ "mgr_opts" = "$CONF_KEY" ]; then
		return 0
	fi
	return 1
}

# Package selection time evaluations
eval_kv_managers () {
	if [ "managers" = "$CONF_KEY" ]; then
		case "$CONF_VALUE" in (*${CONFMAN_MGR}*) return 0; esac
		unset -v DO_INSTALL DO_CONFIGURE
		return 0
	fi
	return 1
}

eval_kv_platforms () {
	if [ "platforms" = "$CONF_KEY" ]; then
		for PATTERN in $CONF_VALUE; do uname -s | grep -i -q "$PATTERN" && return 0; done
		unset -v DO_INSTALL DO_CONFIGURE
		return 0
	fi
	return 1
}

eval_kv_noinstall () {
	case "$CONF_KEY" in
		noinstall) unset -v DO_INSTALL ;;
		*) return 1 ;;
	esac
}

eval_kv_noconfigure () {
	case "$CONF_KEY" in
		noconfigure) unset -v DO_CONFIGURE ;;
		*) return 1 ;;
	esac
}

unknown_key_error () {
	confman -L error "unrecognized key in section '$SECTION' of file '$PKGCONF':\n$CONF_KEY\n"
	return 1
}

### Testing script commands below ###
# set -e
# CONFMAN_MGR=brew parse_section "$1"

