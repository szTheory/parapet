#!/bin/bash
set -e

SANDBOX_DIR="$HOME/parapet_sandbox"
# Automatically resolve to the directory containing this script, then go up one level to the project root
PARAPET_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

echo "🧹 Cleaning up old sandbox at $SANDBOX_DIR..."
rm -rf "$SANDBOX_DIR"

echo "🚀 Creating new Phoenix application (using SQLite)..."
cd "$HOME"
mix phx.new parapet_sandbox --database sqlite3 --no-mailer --install

cd "$SANDBOX_DIR"

echo "📦 Adding parapet and igniter dependencies..."
# Safely insert the dependencies into mix.exs right after the '[' bracket in deps
sed -i.bak '/defp deps do/,/\[/ {
  /\[/a\
      {:parapet, path: "'"$PARAPET_PATH"'", override: true},\
      {:igniter, "~> 0.3"},
}' mix.exs

echo "⬇️  Fetching dependencies..."
mix deps.get

echo "🛠️  Installing Parapet & scaffolding UI..."
mix parapet.install
mix parapet.gen.spine
mix parapet.gen.ui

echo "🗺️  Injecting Parapet routes into router.ex..."
sed -i.bak '/scope "\/", ParapetSandboxWeb do/i\
  scope "/parapet", ParapetSandboxWeb do\
    pipe_through :browser\
    live_session :parapet_operator do\
      live "/", Parapet.OperatorLive, :index\
      live "/:id", Parapet.OperatorDetailLive, :show\
    end\
  end\
' lib/parapet_sandbox_web/router.ex

echo "🌱 Adding realistic seed data..."
cat << 'INNER_EOF' >> priv/repo/seeds.exs

# Parapet Seed Data
alias Parapet.Spine.Incident
alias ParapetSandbox.Repo

Repo.insert!(%Incident{
  title: "High Error Rate on Checkout API",
  description: "Detected 500 errors exceeding 5% threshold in the last 5 minutes.",
  state: "open"
})

Repo.insert!(%Incident{
  title: "Database Latency Spike",
  description: "P99 latency for read operations exceeded 200ms.",
  state: "investigating"
})

Repo.insert!(%Incident{
  title: "Anomalous Login Failures",
  description: "Sudden spike in failed logins originating from a single IP block.",
  state: "resolved"
})
INNER_EOF

echo "🗄️  Setting up the database..."
mix ecto.setup

echo "✅ Done! Start the server with:"
echo "cd $SANDBOX_DIR"
echo "mix phx.server"
echo ""
echo "Then visit: http://localhost:4000/parapet"
