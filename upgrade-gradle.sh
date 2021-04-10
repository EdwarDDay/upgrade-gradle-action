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

echo "::debug::calling: https://services.gradle.org/versions/$releaseChannel"
versionInfo=$(curl "https://services.gradle.org/versions/$releaseChannel")
latestVersion=$(echo "$versionInfo" | jq --raw-output '.version // ""')

while [ -z "$latestVersion" ]; do
  case "$releaseChannel" in
  'current')
    echo '::error::No version in release channel current'
    echo "::error:: Version information from gradle: $versionInfo"
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
  echo "::debug::calling: https://services.gradle.org/versions/$releaseChannel"
  versionInfo=$(curl "https://services.gradle.org/versions/$releaseChannel")
  latestVersion=$(echo "$versionInfo" | jq --raw-output '.version')
done

echo "::debug::Latest gradle version: $latestVersion"
# echo "::set-output name=gradle-version::$latestVersion"

# update gradle wrapper properties
if [ "$distributionType" == "default" ]; then
  ./gradlew wrapper --gradle-version "$latestVersion"
else
  ./gradlew wrapper --gradle-version "$latestVersion" --distribution-type "$distributionType"
fi

# update gradle wrapper
./gradlew wrapper
