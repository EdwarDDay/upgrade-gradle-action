#!/bin/bash

set -e

distributionType="$1"
# verify distribution type
if [ "$distributionType" != 'bin' ] && [ "$distributionType" != 'all' ] && [ "$distributionType" != 'default' ]; then
  echo "::error::Invalid distribution type \"$distributionType\" - must be \"bin\", \"all\" or \"default\""
  exit 1
fi

releaseChannel="$2"
# verify release channel
if [ "$releaseChannel" != 'current' ] && [ "$releaseChannel" != 'release-candidate' ] &&
  [ "$releaseChannel" != 'nightly' ] && [ "$releaseChannel" != 'release-nightly' ]; then
  echo "::error::Invalid release channel \"$releaseChannel\" - must be one of \"current\", \"release-candidate\", \"nightly\" or \"release-nightly\""
  exit 2
fi

latestVersion=''

function retrieveLatestVersion() {
  echo "::debug::calling: https://services.gradle.org/versions/$releaseChannel"
  latestVersion=$(curl "https://services.gradle.org/versions/$releaseChannel" | jq --raw-output '.version // ""')
}

retrieveLatestVersion

while [ -z "$latestVersion" ]; do
  case "$releaseChannel" in
  'current')
    echo '::error::No version in release channel current'
    exit 3
    ;;
  'release-candidate')
    echo '::warn::No version in channel release-candidate, switch to current'
    releaseChannel='current'
    ;;
  'release-nightly')
    echo '::warn::No version in channel release-nightly, switch to nightly'
    releaseChannel='nightly'
    ;;
  'nightly')
    echo '::warn::No version in channel nightly, switch to release-candidate'
    releaseChannel='release-candidate'
    ;;
  esac
  retrieveLatestVersion
done

echo "::debug::Latest gradle version: $latestVersion"
echo "::set-output name=gradle-version::$latestVersion"

# update gradle wrapper properties
if [ "$distributionType" == "default" ]; then
  ./gradlew wrapper --gradle-version "$latestVersion"
else
  ./gradlew wrapper --gradle-version "$latestVersion" --distribution-type "$distributionType"
fi

# update gradle wrapper
./gradlew wrapper

function retrieveInformation() {
  local path="$1"
  echo "::debug::calling https://services.gradle.org/$path/$latestVersion"
  # assume no information on service fail - probably 404
  (curl --fail "https://services.gradle.org/$path/$latestVersion" || echo '[]') | jq --raw-output '.[] | ("- [" + .key + "](" + .link + ") " + .summary )'
}

# add information to release notes page
versionInformation="Upgrade to latest [gradle version $latestVersion](https://docs.gradle.org/$latestVersion/release-notes.html)"

# add information to fixed issues
fixedIssues=$(retrieveInformation 'fixed-issues')
echo "::set-output name=fixed-issues::$fixedIssues"

if [ -n "$fixedIssues" ]; then
  versionInformation="$versionInformation

<details>
<summary>fixed issues</summary>
$fixedIssues
</details>
"
fi

# add information to known issues
knownIssues=$(retrieveInformation 'known-issues')
echo "::set-output name=known-issues::$knownIssues"

if [ -n "$knownIssues" ]; then
  versionInformation="$versionInformation

<details>
<summary>known issues</summary>
$knownIssues
</details>
"
fi

echo "::set-output name=version-information::$versionInformation"
