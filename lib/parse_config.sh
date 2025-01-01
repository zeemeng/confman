#!/usr/bin/env sh

selection_parse_pkgconf () {
	PKGCONF="$CONFMAN_REPO/$PKG/pkg.conf"
	PKGCONF=$1
	while read -r LINE; do
		EOF=0
		while [ 0 = "$EOF" ]; do
			case "$LINE" in
				\[package\]) parse_section package;;
				\[platform.*\]) parse_section platform;;
				\[manager.*\]) parse_section manager;;
				\[*\]) confman -L error "unrecognized section in file '$PKGCONF':\n$LINE\n"; return 1;;
				*) confman -L error "line without a section in file '$PKGCONF':\n$LINE\n"; return 1;;
			esac
		done
	done <<-EOF
		$(sed -e '/^[[:space:]]*$/d' -e '/^#.*/d' "$PKGCONF")
	EOF
}

parse_section () {
	while read -r LINE; do
		case "$LINE" in
			\[*\]) return;;
		esac

		if printf '%s\n' "$LINE" | grep -q '^[[:space:]]*='; then
			confman -L error "invalid key-value pair in file '$PKGCONF', missing key in line:\n$LINE\n"
			return 1
		fi

		CONF_KEY="$(printf '%s\n' "$LINE" | sed -E -e 's/^[[:space:]]//' -e 's/[[:space:]]*=.*$//')"
		CONF_VALUE="$(printf '%s\n' "$LINE" | sed -E -e 's/^[^=]*//' -e 's/=[[:space:]]*//')"
		evaluate_${1}_kvpair
	done
	EOF=1
}

evaluate_package_kvpair () {
	echo "$CONF_KEY>>>$CONF_VALUE<<<"
	case "$CONF_KEY" in
		name)
		;;
		managers)
			case "$CONF_VALUE" in
				*${CONFMAN_MGR}*);;
				*) unset -v DO_INSTALL DO_CONFIGURE;;
			esac
		;;
		platforms)
			for PATTERN in $CONF_VALUE; do
				uname -s | grep -i -q "$PATTERN" && return 0
			done
			unset -v DO_INSTALL DO_CONFIGURE
		;;
		noinstall)
			unset -v DO_INSTALL
		;;
		noconfigure)
			unset -v DO_CONFIGURE
		;;
		*)
			confman -L error "unrecognized key in section 'package' of file '$PKGCONF':\n$CONF_KEY\n"
			return 1
		;;
	esac
}

evaluate_platform_kvpair () {
	echo "$CONF_KEY>>>$CONF_VALUE<<<"
}

evaluate_manager_kvpair () {
	echo "$CONF_KEY>>>$CONF_VALUE<<<"
}
