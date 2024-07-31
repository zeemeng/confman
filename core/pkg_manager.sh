#!/usr/bin/env sh

validate_pkg_manager() {
	_OS=$(uname -s)
	MINGW64_MGR="pacman"
	DARWIN_MGR="brew" # Can be a space-separated list
	LINUX_MGR="apt pacman brew" # Can be a space-separated list


	if [ -z "$PKG_MANAGER" ]; then
		case "$_OS" in
			MINGW64*) PKG_MANAGER="$MINGW64_MGR";;
			Darwin)
				for MGR in $DARWIN_MGR; do
					if command -v "$MGR" >/dev/null; then PKG_MANAGER="$MGR"; fi
				done;;
			*)
				for MGR in $LINUX_MGR; do
					if command -v "$MGR" >/dev/null; then PKG_MANAGER="$MGR"; fi
				done;;
		esac
	fi

	if ! command -v "$PKG_MANAGER" >/dev/null; then
		echo "ERROR: No suitable package manager was found." >&2
		exit 1
	fi

	unset _OS LINUX_MGR DARWIN_MGR MINGW64_MGR
}

# Update/sync back-end package manager repositories with external sources. Set options and environment variables
init_pkg_manager() {
	[ "$PKG_MANAGER" = "apt" ] && sudo apt update && return
	
	[ "$PKG_MANAGER" = "pacman" ] && sudo pacman -Sy && return
	
	if [ "$PKG_MANAGER" = "brew" ]; then
		# Do not run `brew update --auto-update` before certain operations such as install
		export HOMEBREW_NO_AUTO_UPDATE=1

		# Update/sync homebrew repositories
		brew update
	fi
}

