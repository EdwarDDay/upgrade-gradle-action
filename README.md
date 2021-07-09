<!--
SPDX-FileCopyrightText: 2021 Eduard Wolf

SPDX-License-Identifier: Apache-2.0
-->

# Gradle Wrapper Upgrade

[![REUSE status](https://api.reuse.software/badge/github.com/EdwarDDay/upgrade-gradle-action)](https://api.reuse.software/info/github.com/EdwarDDay/upgrade-gradle-action)
[![Develop](https://github.com/EdwarDDay/upgrade-gradle-action/workflows/Develop/badge.svg?branch=main)](https://github.com/EdwarDDay/upgrade-gradle-action/actions?query=workflow%3ADevelop+branch%3Amain)

A GitHub action to upgrade the gradle wrapper of your project.

This action will check for the newest gradle version and upgrade the gradle wrapper properties and the wrapper.

## Usage

Run this action scheduled and create a PR afterwards to review the made changes.

```yaml
    steps:
      - name: checkout
        uses: actions/checkout@v2

      - name: update gradle
        id: gradleUpdate
        uses: EdwarDDay/upgrade-gradle-action@v1

     # create PR
```
You can use whatever PR creation action you want to customize the PR.

This action doesn't check the integrity of the downloaded wrapper. Please use 
[gradle/wrapper-validation-action](https://github.com/marketplace/actions/gradle-wrapper-validation) for a validation
check.

### Action Input
All inputs are optional

|         Name        | Description | Possible values | Default |
|---------------------|-------------|-----------------|---------|
| `distribution-type` | The [distribution type](https://docs.gradle.org/current/userguide/gradle_wrapper.html#sec:adding_wrapper) used in the gradle wrapper task. | `bin`, `all`, `default` | `default` (doesn't specify the distribution type in the gradle wrapper task) |
| `release-channel`   | The [release channel](https://services.gradle.org/versions/) used from which the latest gradle version is fetched. | `current`, `release-candidate`, `nightly`, `release-nightly`  | `current` |
| `working-directoy`  | The directory with the `gradlew` file. | any directory  | `./` |

### Action Output

|          Name         | Description | Example values |
|-----------------------|-------------|----------------|
| `gradle-version`      | The defined gradle version in the gradle `wrapper` task. | `6.8.3`, `7.0`, `7.1-20210410220511+0000` |
| `version-information` | Version information of the `gradle-version`, which can be used in a PR body | Upgrade to latest [gradle version 7.0](https://docs.gradle.org/$7.0/release-notes.html) <br /><br /><details><summary>fixed issues</summary><blockquote> - [#16593](https://github.com/gradle/gradle/issues/16593) Dependency locking of settings classpath isn't properly persisted <br />- ... <br /></blockquote></details> <br /><details><summary>known issues</summary><blockquote>- [#16665](https://github.com/gradle/gradle/issues/16665) Version Catalog + Extensions<br />- ...<br /></blockquote></details>|
| `fixed-issues`        | The fixed issues of the `gradle-version` (can be empty) | - [#16593](https://github.com/gradle/gradle/issues/16593) Dependency locking of settings classpath isn't properly persisted<br />- [#16585](https://github.com/gradle/gradle/issues/16585) Upgrade Bouncy Castle dependency<br />- ... |
| `known-issues`        | The known issues of the `gradle-version` (can be empty) | - [#16665](https://github.com/gradle/gradle/issues/16665) Version Catalog + Extensions <br />- [#16652](https://github.com/gradle/gradle/issues/16652) Trouble using centralized dependency versions in buildSrc plugins and buildscript classpath<br />- ... |

## Example

```yaml
name: Gradle wrapper update

on:
  schedule:
    - cron: '0 6 * * *'

jobs:
  update:
    runs-on: ubuntu-20.04

    steps:
      - name: checkout
        uses: actions/checkout@v2

      - name: update gradle
        id: gradleUpdate
        uses: EdwarDDay/upgrade-gradle-action@v1

      - name: create pull request
        uses: peter-evans/create-pull-request@v3
        with:
          commit-message: "Update gradle to ${{ steps.gradleUpdate.outputs.gradle-version }}"
          branch: "gradle_update/version_${{ steps.gradleUpdate.outputs.gradle-version }}"
          delete-branch: true
          title: "Update gradle to ${{ steps.gradleUpdate.outputs.gradle-version }}"
          body: |
            ${{ steps.gradleUpdate.outputs.version-information }}

            Automated changes by [create-pull-request](https://github.com/peter-evans/create-pull-request) GitHub action
          labels: "dependencies,gradle"
```
