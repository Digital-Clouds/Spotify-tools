#
#  Author: Hari Sekhon
#  Date: 2013-02-03 10:25:36 +0000 (Sun, 03 Feb 2013)
#

ifdef TRAVIS
	SUDO =
else
	SUDO = sudo
endif

.PHONY: make
make:
	[ -x /usr/bin/apt-get ] && make apt-packages || :
	[ -x /usr/bin/yum ]     && make yum-packages || :

	git submodule init
	git submodule update

	cd lib && make

	#@ [ $$EUID -eq 0 ] || { echo "error: must be root to install cpan modules"; exit 1; }
	yes "" | $(SUDO) cpan \
		LWP::Simple \
		Text::Unidecode \
		URI::Escape \
		XML::Simple


.PHONY: apt-packages
apt-packages:
	apt-get install -y gcc || :
	# needed to fetch the library submodule at end of build
	apt-get install -y git || :

.PHONY: yum-packages
yum-packages:
	yum install -y gcc || :
	# needed to fetch the library submodule and CPAN modules
	yum install -y perl-CPAN git || :


.PHONY: test
test:
	cd lib && make test
	# TODO: add functional tests here

.PHONY: install
install:
	@echo "No installation needed, just add '$(PWD)' to your \$$PATH"

.PHONY: update
update:
	git pull
	git submodule update
	make
	make test
