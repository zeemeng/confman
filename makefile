.POSIX:


EXE = build/confman
MAN = doc/confman.1
VERSION_FILE = version


# install dirs variable from GNU make manual
# https://www.gnu.org/software/make/manual/make.html#Directory-Variables
prefix ?= /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(exec_prefix)/lib/confman
mandir = $(exec_prefix)/share/man/man1


.PHONY: all doc install link uninstall rewind forward reinstall relink clean realclean major minor patch
.IGNORE: $(MAN) doc


all: $(EXE)


doc: $(MAN)


.SUFFIXES: .md
.md:
	@printf '\n[make] building man page...\n'
	pandoc '$<' --standalone --to 'man' \
	--output '$@' \
	--variable title='CONFMAN' \
	--variable section='1' \
	--variable date="`date +'%B %Y'`" \
	--variable footer="confman `cat $(VERSION_FILE)`" \


$(MAN): $(VERSION_FILE) makefile


$(EXE): $(EXE:build%=bin%) makefile
	@printf '\n[make] building executable...\n'
	mkdir -p $(@D)
	sed \
	-e 's:^CONFMAN_BIN_PATH=.*$$:CONFMAN_BIN_PATH=$(bindir):' \
	-e 's:^CONFMAN_LIB_PATH=.*$$:CONFMAN_LIB_PATH=$(libdir):' \
	-e 's:^CONFMAN_MAN_PATH=.*$$:CONFMAN_MAN_PATH=$(mandir):' \
	-e "s:^CONFMAN_VERSION=.*$$:CONFMAN_VERSION=`cat "$(VERSION_FILE)"`:" \
	'bin/$(@F)' > '$@'
	chmod 755 '$@'


install: $(MAN) $(EXE)
	@printf '\n[make install] copying executables...\n'
	mkdir -p $(bindir)
	cp $(EXE) $(bindir)
	@printf '\n[make install] copying man pages...\n'
	mkdir -p $(mandir)
	cp $(MAN) $(mandir)
	@printf '\n[make install] copying lib files...\n'
	mkdir -p $(libdir)
	cp -R lib/* $(libdir)


link: $(MAN)
	@printf '\n[make link] linking executables...\n'
	mkdir -p $(bindir)
	ln -sf $(EXE:build%=$(CURDIR)/bin%) $(bindir)
	@printf '\n[make link] linking man pages...\n'
	mkdir -p $(mandir)
	ln -sf $(MAN:%=$(CURDIR)/%) $(mandir)


uninstall:
	@printf '\n[make uninstall] removing executables...\n'
	@rm -fv $(EXE:build%=$(bindir)%)
	@printf '\n[make uninstall] removing man pages...\n'
	@rm -fv $(MAN:doc%=$(mandir)%)
	@printf '\n[make uninstall] removing lib files...\n'
	@rm -rfv $(libdir)


rewind:
	@printf '\n[make rewind] checking out previous git commit on branch...\n'
	git checkout HEAD~


forward:
	@printf '\n[make forward] checking out git branch tip...\n'
	git checkout @{-1}


reinstall:
	make rewind
	make uninstall
	make forward
	make install


relink:
	make rewind
	make uninstall
	make forward
	make link


clean:
	@printf '\n[make clean] removing executable build artifacts...\n'
	rm -rf build


realclean: clean
	@printf '\n[make realclean] removing all build artifacts...\n'
	rm -rf build $(MAN)


major:
	@printf '\n[make major] bumping major semantic version...\n'
	printf "`awk 'BEGIN{FS=OFS="."} /[^[:space:]]/ {print $$1+1,0,0}' $(VERSION_FILE)`\n" > $(VERSION_FILE)
	make $(MAN)


minor:
	@printf '\n[make minor] bumping minor semantic version...\n'
	printf "`awk 'BEGIN{FS=OFS="."} /[^[:space:]]/ {print $$1,$$2+1,0}' $(VERSION_FILE)`\n" > $(VERSION_FILE)
	make $(MAN)


patch:
	@printf '\n[make patch] bumping patch semantic version...\n'
	printf "`awk 'BEGIN{FS=OFS="."} /[^[:space:]]/ {print $$1,$$2,$$3+1}' $(VERSION_FILE)`\n" > $(VERSION_FILE)
	make $(MAN)

