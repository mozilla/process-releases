#!/bin/bash
# Merge from aurora to beta
set -e

if [ -z "$1" ]; then
    echo "betamerge <OLD_BRANCH_POINT>"
    echo
    echo "where OLD_BRANCH_POINT should be the tag/revision we last merged to beta"
    echo "e.g. BETA_BASE_$(date -d'now - 6 weeks' +%Y%m%d)"
    exit 1
fi

OLD_BRANCH_POINT=$1

#hg clone http://hg.mozilla.org/releases/mozilla-aurora
#hg clone http://hg.mozilla.org/releases/mozilla-beta

# Get hgtool from http://hg.mozilla.org/build/tools, in the buildfarm/utils
# directory, and then set HG_SHARE_BASE_DIR to something like $HOME/repos
# to get hg sharing goodness
hgtool.py http://hg.mozilla.org/releases/mozilla-aurora
hgtool.py http://hg.mozilla.org/releases/mozilla-beta

VERSION=$(cat mozilla-aurora/browser/config/version.txt | sed 's/.0a2//')
OLDVERSION=$(cat mozilla-beta/browser/config/version.txt)

aurora_rev=$(hg -R mozilla-aurora id -i -r default)
beta_rev=$(hg -R mozilla-beta id -i -r default)

DATE=$(date +%Y%m%d)

# Close up the old branch
hg tag -R mozilla-beta FIREFOX_BETA_${OLDVERSION}
hg commit -R mozilla-beta --close-branch -m 'closing old head'

# Tag the revision we're basing beta off of
hg tag -R mozilla-aurora BETA_BASE_${DATE}

# Pull aurora changes into beta
hg pull -R mozilla-beta -r BETA_BASE_${DATE} mozilla-aurora
hg update -C -R mozilla-beta

# Version bumps
(cd mozilla-beta; sed -i -e 's/a2//g' browser/config/version.txt js/src/config/milestone.txt config/milestone.txt mobile/confvars.sh)
hg -R mozilla-beta commit -m 'Version bump'

echo "Please review!"
echo hg out -R mozilla-beta
echo hg out -R mozilla-aurora
echo hg log -b default -X mozilla-beta/.hgtags -R mozilla-beta -r ${OLD_BRANCH_POINT}:FIREFOX_BETA_${OLDVERSION}
