PKGNAME ?= snapper-enhanced

.PHONY: install

install:
	@install -Dm644 -t "$(DESTDIR)/etc/apt/apt.conf.d/" 80-snapper-enhanced
	@install -Dm755 -t "$(DESTDIR)/usr/bin/" snapper-enhanced.sh
	@install -Dm644 -t "$(LIB_DIR)/etc/" snapper-enhanced.conf

uninstall:
	rm -f $(DESTDIR)/etc/apt/apt.conf.d/80-snapper-enhanced
	rm -f $(DESTDIR)/usr/bin/snapper-enhanced.sh
