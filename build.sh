#!/usr/bin/env bash
# Render build script: compiles assets and builds a production release.
set -o errexit

mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite
