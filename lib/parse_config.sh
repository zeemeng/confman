#!/usr/bin/env sh

evaluate_ini_config () {
	unset -v OPERATIONS_EVALUATION SELECTIONS_EVALUATION MANAGERS_EVALUATION
	case "$1" in
		--operations) OPERATIONS_EVALUATION=1 ;;
		--managers) MANAGERS_EVALUATION=1 ;;
		*) SELECTIONS_EVALUATION=1 ;;
	esac

	PKGCONF="$CONFMAN_REPO/$PKG/pkg.conf"
#############
### debug ###
# PKGCONF="$2"
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
### debug ###
# printf '\n%s\n' "$SECTION"
#############

	unset -v SKIP_SECTION
	case "$SECTION" in (\[platform.*\])
		PLATFORM_LABEL="$(printf '%s\n' "$SECTION" | sed -E -e 's/^\[platform\.//' -e 's/(\.dependencies|\.environment)?\]$//')"
		uname -s | grep -i -q "$PLATFORM_LABEL" || SKIP_SECTION=1
#############
### debug ###
# echo "---PLATFORM_LABEL--->>>$PLATFORM_LABEL"
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
			# \[package.environment\]) ;;
			\[platform.*\])
				case "$CONF_KEY" in (package) eval_kv_package; esac
				;;
			# \[platform.*.environment\]) ;;
			\[manager.$CONFMAN_MGR\])
				case "$CONF_KEY" in
					package) eval_kv_package ;;
					mgr_opts) eval_kv_mgr_opts ;;
				esac
				;;
			# \[manager.$CONFMAN_MGR.environment\]) ;;
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
### debug ###
# echo "$CONF_KEY>>>$CONF_VALUE"
#############
	PKG="$CONF_VALUE"
}

eval_kv_package () {
#############
### debug ###
# echo "$CONF_KEY>>>$CONF_VALUE"
#############
	PKG="$CONF_VALUE"
}

eval_kv_mgr_opts () {
#############
### debug ###
# echo "$CONF_KEY>>>$CONF_VALUE"
#############
	CONFMAN_MGR_OPTS="$CONF_VALUE"
}

# Package selection time evaluations
eval_kv_managers () {
#############
### debug ###
# echo "$CONF_KEY>>>$CONF_VALUE"
#############
	case "$CONF_VALUE" in (*${CONFMAN_MGR}*) return 0; esac
	unset -v DO_INSTALL DO_CONFIGURE
}

eval_kv_platforms () {
#############
### debug ###
# echo "$CONF_KEY>>>$CONF_VALUE"
#############
	for PATTERN in $CONF_VALUE; do uname -s | grep -i -q "$PATTERN" && return 0; done
	unset -v DO_INSTALL DO_CONFIGURE
}

eval_kv_noinstall () {
#############
### debug ###
# echo "$CONF_KEY>>>$CONF_VALUE"
#############
	unset -v DO_INSTALL
}

eval_kv_noconfigure () {
#############
### debug ###
# echo "$CONF_KEY>>>$CONF_VALUE"
#############
	unset -v DO_CONFIGURE
}

### Testing script commands below ###
#############
### debug ###
# set -e
# CONFMAN_MGR=brew evaluate_ini_config "$@"
#############

