#
#  Author: Hari Sekhon
#  Date: 2013-02-03 10:25:36 +0000 (Sun, 03 Feb 2013)
#

.PHONY: install
install:
	git submodule init
	git submodule update
	#@ [ $$EUID -eq 0 ] || { echo "error: must be root to install cpan modules"; exit 1; }
	sudo cpan \
		LWP::Simple \
		Text::Unidecode \
		URI::Escape \
		XML::Simple

update:
	git pull
	git submodule update
