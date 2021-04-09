# Gradle Wrapper Upgrade

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
        run: EdwarDDay/upgrade-gradle-action@v1

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

### Action Output
The `gradle-version` can be used in the following steps (for example in the PR).

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
        run: EdwarDDay/upgrade-gradle-action@v1

      - name: create pull request
        uses: peter-evans/create-pull-request@v3
        with:
          commit-message: "Update gradle to ${{ steps.gradleUpdate.outputs.gradle-version }}"
          branch: "gradle_update/version_${{ steps.gradleUpdate.outputs.gradle-version }}"
          delete-branch: true
          title: "Update gradle to ${{ steps.gradleUpdate.outputs.gradle-version }}"
          body: |
            New [gradle version ${{ steps.gradleUpdate.outputs.gradle-version }}](https://docs.gradle.org/${{ steps.gradleUpdate.outputs.gradle-version }}/release-notes.html)

            Automated changes by [create-pull-request](https://github.com/peter-evans/create-pull-request) GitHub action
          labels: "dependencies,gradle"
```
