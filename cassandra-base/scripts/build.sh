#!/usr/bin/env bash

set -u

DOCKER=$(which docker)

# build Docker image
"${DOCKER}" build \
            --tag \
              ""cassandra":"base"" \
            --file ./Dockerfile .