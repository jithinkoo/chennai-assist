#!/usr/bin/env bash
# Render build script: compiles assets and builds a production release.
set -o errexit
set -o nounset
set -o pipefail

export MIX_ENV=prod

# Render's build machine has Elixir but not Hex/Rebar. Without them
# `mix deps.get` asks "Shall I install Hex?" and, with no one to answer,
# fetches nothing. Install them non-interactively first.
mix local.hex --force
mix local.rebar --force

mix deps.get --only prod
mix compile
mix assets.deploy
mix release --overwrite
