#!/usr/bin/env sh

evaluate_pkgconf () {
	unset -v OPERATIONS_EVALUATION SELECTIONS_EVALUATION MANAGERS_EVALUATION
	case "$1" in
		--operations) OPERATIONS_EVALUATION=1 ;;
		--managers) MANAGERS_EVALUATION=1 ;;
		*) SELECTIONS_EVALUATION=1 ;;
	esac

	PKGCONF="$CONFMAN_REPO/$PKG/pkg.conf"
#############
# PKGCONF="$2" ### debug ###
#############

	while read -r SECTION; do
		EOF=0; while [ 0 = "$EOF" ]; do
			case "$SECTION" in
				\[package*\] | \[platform.*\] | \[manager.*\]) ;;
				\[*\]) confman -L error "unrecognized section in file '$PKGCONF':\n$SECTION\n"; return 1;;
				*) confman -L error "line without a section in file '$PKGCONF':\n$SECTION\n"; return 1;;
			esac

			evaluate_kvpairs
		done
	done <<-EOF
		$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#.*/d' "$PKGCONF")
	EOF
}

evaluate_kvpairs () {
#############
# printf '\n%s\n' "$SECTION" ### debug ###
#############

	unset -v SKIP_SECTION
	case "$SECTION" in (\[platform.*\])
		PLATFORM_LABEL="$(printf '%s\n' "$SECTION" | sed -E -e 's/^\[platform\.//' -e 's/(\.dependencies|\.environment)?\]$//')"
		uname -s | grep -i -q "$PLATFORM_LABEL" || SKIP_SECTION=1
#############
# echo "---PLATFORM_LABEL--->>>$PLATFORM_LABEL" ### debug ###
#############
	esac

	while read -r LINE; do
		# Hit the next section's header; return control to outer while loop
		case "$LINE" in (\[*\])
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

		[ "$SKIP_SECTION" ] && continue

		[ "$SELECTIONS_EVALUATION" ] && case "$SECTION" in
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

		[ "$OPERATIONS_EVALUATION" ] && case "$SECTION" in
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

		[ "$MANAGERS_EVALUATION" ] && case "$SECTION" in
			\[manager.platforms\]) ;;
			\[manager.operations\]) ;;
		esac
	done
	EOF=1
}

# Operations time evaluations
eval_kv_name () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug ###
#############
	PKG="$CONF_VALUE"
}

eval_kv_mgr_opts () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug ###
#############
	CONFMAN_MGR_OPTS="$CONF_VALUE"
}

# Package selection time evaluations
eval_kv_managers () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug ###
#############
	case "$CONF_VALUE" in (*${CONFMAN_MGR}*) return 0; esac
	unset -v DO_INSTALL DO_CONFIGURE
}

eval_kv_platforms () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug ###
#############
	for PATTERN in $CONF_VALUE; do uname -s | grep -i -q "$PATTERN" && return 0; done
	unset -v DO_INSTALL DO_CONFIGURE
}

eval_kv_noinstall () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug ###
#############
	unset -v DO_INSTALL
}

eval_kv_noconfigure () {
#############
# echo "$CONF_KEY>>>$CONF_VALUE" ### debug ###
#############
	unset -v DO_CONFIGURE
}

### Testing script commands below ###
#############
# set -e ### debug ###
# CONFMAN_MGR=brew evaluate_pkgconf "$@" ### debug ###
#############

