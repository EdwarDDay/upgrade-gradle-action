#!/bin/bash

# SPDX-FileCopyrightText: 2021 Eduard Wolf
#
# SPDX-License-Identifier: Apache-2.0

set -e

distributionType="$1"
# verify distribution type
if [ "$distributionType" != 'bin' ] && [ "$distributionType" != 'all' ] && [ "$distributionType" != 'default' ]; then
  echo "::error::Invalid distribution type \"$distributionType\" - must be \"bin\", \"all\" or \"default\""
  exit 1
fi
if [ "$distributionType" == "default" ]; then
  distributionType='bin'
fi

releaseChannel="$2"
# verify release channel
if [ "$releaseChannel" != 'current' ] && [ "$releaseChannel" != 'release-candidate' ] &&
  [ "$releaseChannel" != 'nightly' ] && [ "$releaseChannel" != 'release-nightly' ]; then
  echo "::error::Invalid release channel \"$releaseChannel\" - must be one of \"current\", \"release-candidate\", \"nightly\" or \"release-nightly\""
  exit 2
fi

validateDistributionChecksum="$3"
if [ "$validateDistributionChecksum" != 'true' ] && [ "$validateDistributionChecksum" != 'false' ]; then
  echo "::error::Invalid validate distribution checksum option \"$validateDistributionChecksum\" - must be one of \"true\" or \"false\""
  exit 3
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
    exit 4
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

distributionSha256Sum=''
checksumArg=''

if [ "$validateDistributionChecksum" == "true" ]; then
  if [ "$releaseChannel" != 'nightly' ] && [ "$releaseChannel" != 'release-nightly' ]; then
    echo "::debug::calling: https://services.gradle.org/distributions/gradle-$latestVersion-$distributionType.zip.sha256"
    distributionSha256Sum="$(curl -L "https://services.gradle.org/distributions/gradle-$latestVersion-$distributionType.zip.sha256")"
  else
    echo "::debug::calling: https://services.gradle.org/distributions-snapshots/gradle-$latestVersion-$distributionType.zip.sha256"
    distributionSha256Sum="$(curl -L "https://services.gradle.org/distributions-snapshots/gradle-$latestVersion-$distributionType.zip.sha256")"
  fi
  echo "::debug::Gradle distribution sha256 sum: $distributionSha256Sum"
  echo "::set-output name=gradle-distribution-sha256-sum::$distributionSha256Sum"

  checksumArg="--gradle-distribution-sha256-sum=$distributionSha256Sum"
fi

echo "::debug::Updating wrapper properties (with existing wrapper & gradle version)"
# shellcheck disable=SC2086
./gradlew wrapper "--gradle-version=$latestVersion" "--distribution-type=$distributionType" $checksumArg

echo "::debug::Running wrapper to download, validate distribution & update the wrapper itself (with target gradle version)"
# shellcheck disable=SC2086
./gradlew wrapper "--gradle-version=$latestVersion" "--distribution-type=$distributionType" $checksumArg

# https://github.community/t/set-output-truncates-multiline-strings/16852/3
function escapeVariable() {
  local content="$1"
  local content="${content//'%'/'%25'}"
  local content="${content//$'\n'/'%0A'}"
  local content="${content//$'\r'/'%0D'}"
  echo "$content"
}

function retrieveInformation() {
  local path="$1"
  # assume no information on service fail - probably 404
  (curl --fail "https://services.gradle.org/$path/$latestVersion" || echo '[]') | jq --raw-output '.[] | ("- [" + .key + "](" + .link + ") " + .summary )'
}

# add information to release notes page
versionInformation="Upgrade to latest [gradle version $latestVersion](https://docs.gradle.org/$latestVersion/release-notes.html)"

# add information to fixed issues
echo "::debug::calling https://services.gradle.org/fixed-issues/$latestVersion"
fixedIssues=$(retrieveInformation 'fixed-issues')

if [ -n "$fixedIssues" ]; then
  versionInformation="$versionInformation

<details><summary>fixed issues</summary>

$fixedIssues
</details>"
fi

fixedIssues=$(escapeVariable "$fixedIssues")
echo "::set-output name=fixed-issues::$fixedIssues"

# add information to known issues
echo "::debug::calling https://services.gradle.org/known-issues/$latestVersion"
knownIssues=$(retrieveInformation 'known-issues')

if [ -n "$knownIssues" ]; then
  versionInformation="$versionInformation

<details><summary>known issues</summary>

$knownIssues
</details>"
fi

knownIssues=$(escapeVariable "$knownIssues")
echo "::set-output name=known-issues::$knownIssues"

versionInformation=$(escapeVariable "$versionInformation")
echo "::set-output name=version-information::$versionInformation"
