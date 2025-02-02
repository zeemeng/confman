#!/usr/bin/env sh

# !! NON-POSIX feature available in BSD, GNU/Linux and MacOS: options -s and -v of "cp"
# Not used, since MacOS 14.1 has a bug where the "-s" option does not work as expected.
rlink() (
	set -- "$(realpath "$1")" "$2" # use absolute path as link source

	if [ ! -d "$1" ]; then printf "Creating symlink: "; ln -sfv "$1" "$2"; return 0; fi

	if [ ! -r "$1" ]; then printf "[rlink] error: cannot read link source directory: $1\n" >&2; exit 1; fi

	mkdir -p "$2"

	for ITEM in $(ls -1AL "$1"); do
		if [ ! -d "$1/$ITEM" ]; then printf "Creating symlink: "; ln -sfv "$1/$ITEM" "$2"; continue; fi
		rlink "$1/$ITEM" "$2/$ITEM"
	done
)

default_configure () {
	SRC_DIR="${SRC_DIR-$CONFMAN_REPO/$1/data}"
	LINK_TARGET="${LINK_TARGET-$CONFMAN_DEST}"
	if [ -d "$SRC_DIR" ]; then rlink "$SRC_DIR" "$LINK_TARGET"; fi
}

delink() (
	safe_unlink () {
		if [ ! -e "$2" ]; then return 0; fi
		if [ -d "$1" ] || [ ! -L "$2" ] || [ "$1" != "$(realpath "$2")" ]; then
			printf '[delink] error: link source does not match link target\n\tsource: %s\n\ttarget: %s\n\t%s\n' "$1" "$2" >&2
			exit 1
		fi
		printf 'Removing symlink: '
		rm -fv "$2"
	}

	set -- "$(realpath "$1")" "$2" # use absolute path as link source

	# [Case 1] $1:source --> file (symlink origin), $2:target --> file (symlink)
	if [ ! -d "$2" ]; then safe_unlink "$1" "$2"; return; fi

	# [Case 2] $1:source --> file (symlink origin), $2:target --> dir (parent of symlink)
	if [ ! -d "$1" ]; then safe_unlink "$1" "$2/$(basename "$1")"; return; fi

	# [Case 3] $1:source --> dir (parent of symlink origin), $2:target --> dir (parent of symlink)
	if [ ! -r "$1" ]; then printf "[delink] error: cannot read link source directory: $1\n" >&2; exit 1; fi
	for ITEM in $(ls -1AL "$1"); do
		if [ ! -d "$1/$ITEM" ]; then
			safe_unlink "$1/$ITEM" "$2/$ITEM"
		else
			delink "$1/$ITEM" "$2/$ITEM"
		fi
	done
	if [ -z "$(ls -1AL "$2")" ]; then
		printf "Removing empty directory: "
		rm -fdv "$2"
	fi
)

default_unconfigure () {
	SRC_DIR="${SRC_DIR-$CONFMAN_REPO/$1/data}"
	LINK_TARGET="${LINK_TARGET-$CONFMAN_DEST}"
	if [ -d "$SRC_DIR" ]; then delink "$SRC_DIR" "$LINK_TARGET"; fi
}

default_install () {
	sh -c "$CONFMAN_INSTALL_CMD"
}

default_uninstall () {
	sh -c "$CONFMAN_UNINSTALL_CMD"
}

default_update () {
	sh -c "$CONFMAN_UPDATE_CMD"
}

