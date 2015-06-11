#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/harisekhon
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

set -eu
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$srcdir/..";

export PERLBREW_ROOT="${PERLBREW_ROOT:-~/perl5/perlbrew}"

export TRAVIS_PERL_VERSION="${TRAVIS_PERL_VERSION:-*}"

# For Travis CI which installs modules locally
export PERL5LIB=$(echo \
    ${PERL5LIB:-.} \
    $PERLBREW_ROOT/perls/$TRAVIS_PERL_VERSION/lib/site_perl/$TRAVIS_PERL_VERSION.*/x86_64-linux \
    $PERLBREW_ROOT/perls/$TRAVIS_PERL_VERSION/lib/site_perl/$TRAVIS_PERL_VERSION.* \
    $PERLBREW_ROOT/perls/$TRAVIS_PERL_VERSION/lib/$TRAVIS_PERL_VERSION.*/x86_64-linux \
    $PERLBREW_ROOT/perls/$TRAVIS_PERL_VERSION/lib/$TRAVIS_PERL_VERSION.* \
    | tr '\n' ':'
)
# Taint code doesn't use PERL5LIB, use -I instead
I_lib=""
for x in $(echo "$PERL5LIB" | tr ':' ' '); do
    I_lib+="-I $x "
done

URI='http://open.spotify.com/track/1j6API7GnhE8MRRedK4bda'
EXPECTED="Pendulum - Witchcraft"

echo "running spotify-lookup.pl against Spotify API"
result=$(perl -T $I_lib spotify-lookup.pl <<< "$URI")
if [ "$result" = "$EXPECTED" ]; then
    echo "Correctly resolved '$URI' => '$result'"
    exit 0
else
    echo "FAILED to resolve '$URI' => '$EXPECTED', got '$result' instead"
    exit 1
fi
