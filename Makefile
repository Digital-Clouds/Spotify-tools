#  vim:ts=4:sts=4:sw=4:noet
#
#  Author: Hari Sekhon
#  Date: 2013-02-03 10:25:36 +0000 (Sun, 03 Feb 2013)
#
#  https://github.com/harisekhon/spotify-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#  to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

ifdef TRAVIS
	SUDO2 =
	CPANM = cpanm
else
	SUDO2 = sudo
	CPANM = /usr/local/bin/cpanm
endif

# EUID /  UID not exported in Make
# USER not populated in Docker
ifeq '$(shell id -u)' '0'
	SUDO =
	SUDO2 =
else
	SUDO = sudo
endif


.PHONY: build
build:
	if [ -x /sbin/apk ];        then make apk-packages; fi
	if [ -x /usr/bin/apt-get ]; then make apt-packages; fi
	if [ -x /usr/bin/yum ];     then make yum-packages; fi

	git submodule init
	git submodule update --recursive

	cd lib && make

	#@ [ $$EUID -eq 0 ] || { echo "error: must be root to install cpan modules"; exit 1; }
	yes "" | $(SUDO2) cpan App::cpanminus
	yes "" | $(SUDO2) $(CPANM) --notest \
		LWP::Simple \
		Text::Unidecode \
		URI::Escape \
		XML::Simple
	@echo
	@echo "BUILD SUCCESSFUL (spotify-tools)"

.PHONY: apk-packages
apk-packages:
	$(SUDO) apk update
	$(SUDO) apk add \
		alpine-sdk \
		bash \
		expat-dev \
		gcc \
		git \
		make \
		openssl-dev \
		perl \
		perl-dev \
		wget

.PHONY: apk-packages-remove
apk-packages-remove:
	cd lib && make apk-packages-remove
	$(SUDO) apk del \
		alpine-sdk \
		expat-dev \
		gcc \
		openssl-dev \
		perl-dev \
		wget \
		:
	$(SUDO) rm -fr /var/cache/apk/*

.PHONY: apt-packages
apt-packages:
	$(SUDO) apt-get install -y gcc
	# needed to fetch the library submodule at end of build
	$(SUDO) apt-get install -y git

.PHONY: yum-packages
yum-packages:
	rpm -q gcc || $(SUDO) yum install -y gcc
	# needed to fetch the library submodule and CPAN modules
	rpm -q git || $(SUDO) yum install -y git
	rpm -q perl-CPAN || $(SUDO) yum install -y perl-CPAN

.PHONY: test
test:
	cd lib && make test
	tests/all.sh

.PHONY: install
install:
	@echo "No installation needed, just add '$(PWD)' to your \$$PATH"

.PHONY: update
update:
	make update-no-recompile
	make
	@#make test

.PHONY: update2
update2:
	make update-no-recompile

.PHONY: update-no-recompile
update-no-recompile:
	git pull
	git submodule update --init --recursive

.PHONY: update-submodules
update-submodules:
	git submodule update --init --remote
.PHONY: updatem
updatem:
	make update-submodules

.PHONY: clean
clean:
	@echo Nothing to clean
