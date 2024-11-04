#!/usr/bin/env sh

# Technically unnecessary, since 'utils.sh' already sourced in main 'confman' script, but re-sourcing for clarity.
. "$CONFMAN_DIR/lib/utils.sh"

select_pkg_mgr_from () {
	for MGR; do
		if command -v "$MGR" >/dev/null; then
			CONFMAN_MGR="$MGR"
			return 0
		fi
	done
}

validate_pkg_manager() {
	MINGW64_MGR="pacman"
	DARWIN_MGR="brew" # Can be a space-separated list
	LINUX_MGR="apt pacman brew" # Can be a space-separated list

	if [ -z "$CONFMAN_MGR" ]; then
		case "$(uname -s)" in
			MINGW64*|MSYS*) select_pkg_mgr_from $MINGW64_MGR ;;
			Darwin) select_pkg_mgr_from $DARWIN_MGR ;;
			*) select_pkg_mgr_from $LINUX_MGR ;;
		esac
	fi

	if ! command -v "$CONFMAN_MGR" >/dev/null; then
		"$CONFMAN_LOG" error "No suitable package manager was found."
		exit 1
	fi

	unset LINUX_MGR DARWIN_MGR MINGW64_MGR
}

# Update/sync back-end package manager repositories with external sources. Set options and environment variables
init_pkg_manager() {
	[ "$CONFMAN_MGR" = "apt" ] && sudo apt update && return

	[ "$CONFMAN_MGR" = "pacman" ] && sudo pacman -Sy && return

	if [ "$CONFMAN_MGR" = "brew" ]; then
		# Do not run `brew update --auto-update` before certain operations such as install
		export HOMEBREW_NO_AUTO_UPDATE=1

		# Update/sync homebrew repositories
		brew update
	fi
}

