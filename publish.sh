#!/bin/bash
set -e

if [ -z ${LAUNCHPADUSER+x} ]; then
    echo "\$LAUNCHPADUSER not set, please set this to your Launchpad user name."
    exit 1
fi

if [ -z ${1+x} ]; then
    echo "Usage: $0 [distribution,distribution,...]"
    echo "For example: $0 trusty,xenial"
    exit 1
fi

#get all of the packages ready
NO_BUILD=true ./package.sh "${1}"
IFS=',' read -r -a DISTRIBUTIONS <<< "${1}"
VERSION=$(head debian/changelog -n1 | sed -e "s/.*(//g" -e "s/-[a-zA-Z0-9+~\.]\+).*//;s/).*//")

#have to have a branch of the code up there or the packages wont work from the ppa
cd ${DISTRIBUTIONS[0]}/unpinned
bzr init
bzr add
bzr commit -m "Packaging for ${VERSION}-0ubuntu1."
bzr push --overwrite bzr+ssh://${LAUNCHPADUSER}@bazaar.launchpad.net/~valhalla-core/+junk/osmlr_${VERSION}-0ubuntu1
cd -

#sign and push each package to launchpad
for dist in ${DISTRIBUTIONS[@]}; do
	for pin in pinned unpinned; do
		debsign ${dist}/${pin}/*source.changes
		dput ppa:valhalla-core/opentraffic ${dist}/${pin}/*source.changes
	done
done
