# syntax=docker/dockerfile:1.7
FROM elixir:1.19-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN --mount=type=cache,target=/root/.hex \
    --mount=type=cache,target=/root/.mix \
    mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=dev

# Step 1: Install parent dependencies. Build context is the repo root.
COPY mix.exs mix.lock ./
COPY lib/ ./lib/
COPY priv/ ./priv/
# We need to compile the parent library first so the demo app can depend on it
RUN --mount=type=cache,target=/root/.hex \
    --mount=type=cache,target=/root/.cache/rebar3 \
    mix deps.get && mix compile

# Now move to the demo app
WORKDIR /app/examples/demo_app

# Copy demo app dep files
COPY examples/demo_app/mix.exs examples/demo_app/mix.lock ./

# Fetch demo app dependencies
RUN --mount=type=cache,target=/root/.hex \
    --mount=type=cache,target=/root/.cache/rebar3 \
    mix deps.get

# Compile dependencies only
RUN mix deps.compile

# Step 2: Copy config and assets (changes less frequently than lib)
COPY examples/demo_app/config/ ./config/
COPY examples/demo_app/assets/ ./assets/
COPY examples/demo_app/priv/ ./priv/

# Step 3: Copy application code (changes most frequently)
# If a UI tweak happens here, layers 1 and 2 remain perfectly cached!
COPY examples/demo_app/lib/ ./lib/

# Step 4: Compile assets (Tailwind scans lib/ at this step)
RUN mix assets.deploy

# Step 5: Compile the application
RUN mix compile

# Expose Phoenix port
EXPOSE 4000

# Start the Phoenix server
CMD ["mix", "phx.server"]
