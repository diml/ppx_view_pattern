INSTALL_ARGS := $(if $(PREFIX),--prefix $(PREFIX),)

default:
	jbuilder runtest --dev

all:
	jbuilder build --dev

install:
	jbuilder install $(INSTALL_ARGS)

uninstall:
	jbuilder uninstall $(INSTALL_ARGS)

reinstall: uninstall reinstall

test:
	jbuilder runtest --dev

clean:
	rm -rf _build *.install
	find . -name .merlin -delete
