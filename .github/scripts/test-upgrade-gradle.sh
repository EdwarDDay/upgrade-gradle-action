#!/bin/bash

set -e

gradle init --type basic --dsl kotlin --project-name test-project

./gradlew wrapper --gradle-version 6.0
