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


# testing related variables
image ?= debian
TAG = confman:$(image)
CONTAINER = confman_$(image)


.PHONY: all doc install link uninstall rewind forward reinstall relink clean realclean major minor patch image images container container_new
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
	-e "s:^CONFMAN_USAGE=.*$$:CONFMAN_USAGE='`awk '/^# SYNOPSIS$$/{p=1; next} p && /^$$/{exit} p' doc/confman.1.md | sed -E -e 's/\*+([^*[:space:]]+)\*+/\1/g'`':" \
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
	docker images -q --filter=reference=confman | xargs docker image rm --force


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


image:
	@printf '\n[make image] building image --> $(TAG)\n'
	docker build -t "$(TAG)" -f "test/e2e/docker/$(image).dockerfile" .

	@printf '\n[make image] cleaning intermediate image layers\n'
	docker image prune -f

images:
	@printf '\n[make images] building all images\n'
	for IMG in test/e2e/docker/*; do make image image=`basename $$IMG .dockerfile` || exit 1; done

container:
	@if docker container inspect "$(CONTAINER)"; then \
		printf '\n[make container] cleaning prior container --> $(CONTAINER)\n'; \
		docker stop "$(CONTAINER)"; \
		docker rm -vf "$(CONTAINER)"; \
	fi >/dev/null 2>&1

	@printf '\n[make container] starting container --> $(CONTAINER)\n'
	@if docker image inspect "$(TAG)" >/dev/null 2>&1; then \
		docker run --name "$(CONTAINER)" -it "$(TAG)"; \
	else \
		printf "\n[make container] ERROR: Cannot find Docker image --> $(TAG)\n" >&2 && exit 1; \
	fi

	@printf '\n[make container] stopping container --> $(CONTAINER)\n'
	@docker stop "$(CONTAINER)" >/dev/null


container_new:
	make image container

