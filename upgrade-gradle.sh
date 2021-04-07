#!/bin/bash

set -e

distributionType=$1
# verify distribution type
if [ "$distributionType" != "bin" ] && [ "$distributionType" != "all" ]; then
  echo "::error::Invalid distribution type \"$distributionType\" - must be \"bin\" or \"all\""
  exit 1
fi

releaseChannel=$2
if [ "$releaseChannel" != "current" ] && [ "$releaseChannel" != "release-candidate" ] &&
  [ "$releaseChannel" != "nightly" ] && [ "$releaseChannel" != "release-nightly" ]; then
  echo "::error::Invalid release channel \"$releaseChannel\" - must be one of \"current\", \"release-candidate\", \"nightly\" or \"release-nightly\""
  exit 2
fi

latestVersion=$(curl "https://services.gradle.org/versions/$releaseChannel" | jq --raw-output '.version')

echo "::debug::Latest gradle version: $latestVersion"
echo "::set-output name=gradle-version::$latestVersion"

# update gradle properties
./gradlew wrapper --gradle-version "$latestVersion" --distribution-type "$distributionType"

# update gradle wrapper
./gradlew wrapper
