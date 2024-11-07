#!/bin/bash

# SPDX-FileCopyrightText: 2021 Eduard Wolf
#
# SPDX-License-Identifier: Apache-2.0

set -e

gradle init --overwrite --type basic --dsl kotlin --project-name test-project

rm gradle/libs.versions.toml

./gradlew wrapper --gradle-version 7.0
