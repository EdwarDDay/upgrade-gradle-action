#!/bin/bash

# SPDX-FileCopyrightText: 2021 Eduard Wolf
#
# SPDX-License-Identifier: Apache-2.0

set -e

distributionType="$1"
# verify distribution type
if [ "${distributionType}" != 'bin' ] && [ "${distributionType}" != 'all' ] && [ "${distributionType}" != 'default' ]; then
  echo "::error::Invalid distribution type \"${distributionType}\" - must be \"bin\", \"all\" or \"default\""
  exit 1
fi

releaseChannel="$2"
# verify release channel
if [ "${releaseChannel}" != 'current' ] && [ "${releaseChannel}" != 'release-candidate' ] &&
  [ "${releaseChannel}" != 'nightly' ] && [ "${releaseChannel}" != 'release-nightly' ]; then
  echo "::error::Invalid release channel \"${releaseChannel}\" - must be one of \"current\", \"release-candidate\", \"nightly\" or \"release-nightly\""
  exit 2
fi

addShaChecksum="$3"
# verify sha checksum input
if [ "${addShaChecksum}" != 'true' ] && [ "${addShaChecksum}" != 'false' ]; then
  echo "::error::Invalid add sha checksum value \"${addShaChecksum}\" - must be one of \"true\" or \"false\""
  exit 3
fi

if [ "${addShaChecksum}" == 'true' ] && [ "${distributionType}" == 'default' ]; then
  echo "::error::Cannot add sha checksum without setting the distribution type"
  exit 4
fi

latestVersion=''

function retrieveLatestVersion() {
  echo "::debug::calling: https://services.gradle.org/versions/${releaseChannel}"
  latestVersion=$(curl "https://services.gradle.org/versions/${releaseChannel}" | jq --raw-output '.version // ""')
}

retrieveLatestVersion

while [ -z "${latestVersion}" ]; do
  case "${releaseChannel}" in
  'current')
    echo '::error::No version in release channel current'
    exit 5
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

echo "::debug::Latest gradle version: ${latestVersion}"
echo "gradle-version=${latestVersion}" >> "${GITHUB_OUTPUT}"

sha256sum='""'

# update gradle wrapper properties
if [ "${distributionType}" == "default" ]; then
  ./gradlew wrapper --gradle-version "${latestVersion}"
  # update gradle wrapper
  ./gradlew wrapper
elif [ "${addShaChecksum}" == 'true' ]; then
  distributionPath='distributions'
  if [[ "$releaseChannel" =~ nightly$ ]]; then
      distributionPath='distributions-snapshots'
  fi
  echo "::debug::calling: https://services.gradle.org/${distributionPath}/gradle-${latestVersion}-${distributionType}.zip.sha256"
  sha256sum=$(curl --location "https://services.gradle.org/${distributionPath}/gradle-${latestVersion}-${distributionType}.zip.sha256")
  echo "::debug::sha-256-sum: $sha256sum"
  ./gradlew wrapper --gradle-version "${latestVersion}" --distribution-type "${distributionType}" --gradle-distribution-sha256-sum  "$sha256sum"
  # update gradle wrapper
  ./gradlew wrapper --distribution-type "${distributionType}"
else
  ./gradlew wrapper --gradle-version "${latestVersion}" --distribution-type "${distributionType}"
  # update gradle wrapper
  ./gradlew wrapper --distribution-type "${distributionType}"
fi

echo "sha-256-sum=${sha256sum}" >> "${GITHUB_OUTPUT}"

# https://github.com/orgs/community/discussions/26288#discussioncomment-3876281
function outputMultilineVariable() {
  local name="$1"
  local content="$2"
  local delimiter
  delimiter="$(openssl rand -hex 8)"
  {
    echo "${name}<<${delimiter}"
    echo "${content}"
    echo "${delimiter}"
  } >> "${GITHUB_OUTPUT}"
}

function retrieveInformation() {
  local path="$1"
  # assume no information on service fail - probably 404
  (curl --fail "https://services.gradle.org/${path}/${latestVersion}" || echo '[]') | jq --raw-output '.[] | ("- [" + .key + "](" + (.link | sub("https://github[.]com/"; "https://redirect.github.com/")) + ") " + .summary )'
}

# add information to release notes page
versionInformation="Upgrade to latest [gradle version ${latestVersion}](https://docs.gradle.org/${latestVersion}/release-notes.html)"

# add information to fixed issues
echo "::debug::calling https://services.gradle.org/fixed-issues/${latestVersion}"
fixedIssues=$(retrieveInformation 'fixed-issues')

if [ -n "${fixedIssues}" ]; then
  versionInformation="${versionInformation}

<details><summary>fixed issues</summary>

${fixedIssues}
</details>"
fi

outputMultilineVariable "fixed-issues" "${fixedIssues}"

# add information to known issues
echo "::debug::calling https://services.gradle.org/known-issues/${latestVersion}"
knownIssues=$(retrieveInformation 'known-issues')

if [ -n "${knownIssues}" ]; then
  versionInformation="${versionInformation}

<details><summary>known issues</summary>

${knownIssues}
</details>"
fi

outputMultilineVariable "known-issues" "${knownIssues}"

outputMultilineVariable "version-information" "${versionInformation}"
