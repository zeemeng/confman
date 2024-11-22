.POSIX:

BUILD=build/confman
BUILD_SRC=bin/confman
MAN=doc/confman.1
MAN_SRC=doc/confman.1.md
VERSION_FILE=version
INSTALL_PREFIX=/usr/local

INSTALL_BIN_PATH=$(INSTALL_PREFIX)/bin
INSTALL_LIB_PATH=$(INSTALL_PREFIX)/lib/confman
INSTALL_MAN_PATH=$(INSTALL_PREFIX)/share/man/man1


all: $(MAN)


$(MAN): $(MAN_SRC) $(VERSION_FILE)
	pandoc "$(MAN_SRC)" --standalone --to "man" \
	--output "$(MAN)" \
	--variable title="CONFMAN" \
	--variable section="1" \
	--variable date="$$(date +'%B %Y')" \
	--variable footer="confman $$(cat $(VERSION_FILE))" \


$(BUILD): $(BUILD_SRC)
	for ITEM in $^; do sed \
	-e 's:^CONFMAN_BIN_PATH=.*$$:CONFMAN_BIN_PATH=$(INSTALL_BIN_PATH):'
	-e 's:^CONFMAN_LIB_PATH=.*$$:CONFMAN_LIB=$(INSTALL_LIB_PATH):' \
	-e 's:^CONFMAN_MAN_PATH=.*$$:CONFMAN_MANPATH=$(INSTALL_MAN_PATH):' \
	-e "s:^CONFMAN_VERSION=.*$$:CONFMAN_VERSION=$$(cat "$(VERSION_FILE)"):") \
	"$$ITEM" > "build/$$(basename "$$ITEM")"; done


install: $(MAN) $(BUILD)
	mkdir -p $(INSTALL_BIN_PATH)
	cp $(BUILD) $(INSTALL_BIN_PATH)

	mkdir -p $(INSTALL_MAN_PATH)
	cp $(MAN) $(INSTALL_MAN_PATH)

	mkdir -p $(INSTALL_LIB_PATH)
	cp -R lib/* $(INSTALL_LIB_PATH)


link: $(MAN)
	mkdir -p $(INSTALL_BIN_PATH)
	ln -sf $(BUILD_SRC) $(INSTALL_BIN_PATH)

	mkdir -p $(INSTALL_MAN_PATH)
	ln -sf $(MAN) $(INSTALL_MAN_PATH)


uninstall:
	for EXE in $(BUILD_SRC); do rm -fv $(INSTALL_BIN_PATH)/"$$(basename "$$EXE")"; done
	rm -fv $(INSTALL_MAN_PATH)/"$$(basename $(MAN))"
	rm -rfv $(INSTALL_LIB_PATH)


rewind:
	git checkout HEAD~


forward:
	git checkout @{-1}


reinstall: rewind uninstall forward install


relink: rewind uninstall forward link


patch: bump_patch $(MAN)
bump_patch:
	printf "$$(awk 'BEGIN{FS=OFS="."} /[^[:space:]]/ {print $$1,$$2,$$3+1}' $(VERSION_FILE))\n" > $(VERSION_FILE)


minor: bump_minor $(MAN)
bump_minor:
	printf "$$(awk 'BEGIN{FS=OFS="."} /[^[:space:]]/ {print $$1,$$2+1,0}' $(VERSION_FILE))\n" > $(VERSION_FILE)


major: bump_major $(MAN)
bump_major:
	printf "$$(awk 'BEGIN{FS=OFS="."} /[^[:space:]]/ {print $$1+1,0,0}' $(VERSION_FILE))\n" > $(VERSION_FILE)

