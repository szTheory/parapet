#!/bin/bash
set -e

# Build parent library deps
cd /app
mix deps.get
mix deps.compile

# Build demo app deps
cd /app/examples/demo_app
mix deps.get
mix deps.compile

# Setup database and start server
mix setup
exec mix phx.server
