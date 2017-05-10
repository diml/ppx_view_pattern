INSTALL_ARGS := $(if $(PREFIX),--prefix $(PREFIX),)

all:
	jbuilder build --dev

install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall reinstall

test:
	jbuilder runtest

clean:
	rm -rf _build *.install
	find . -name .merlin -delete
