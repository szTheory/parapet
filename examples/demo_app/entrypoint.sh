#!/usr/bin/env bash
set -euo pipefail

cd /app/examples/demo_app
mix deps.get

mix ecto.create
mix ecto.migrate

if mix run -e 'alias DemoApp.Repo; alias Parapet.Spine.Incident; if Repo.aggregate(Incident, :count, :id) == 0, do: System.halt(0), else: System.halt(1)'; then
  mix run priv/repo/seeds.exs
else
  echo "Demo data already present; skipping seeds."
fi

mix assets.build

exec mix phx.server
