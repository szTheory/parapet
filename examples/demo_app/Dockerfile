# Use a robust Elixir base image with Erlang/OTP and Alpine/Debian
# Using the standard Elixir image which is based on Debian
FROM elixir:1.15-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=dev

# Step 1: Install mix dependencies
# We copy ONLY the files needed to fetch and compile dependencies.
# This means if you change a UI component in lib/, this layer remains cached.
COPY mix.exs mix.lock ./
COPY priv/templates/ ./priv/templates/

# In a monorepo setup where the demo app depends on the parent directory,
# we need the parent mix.exs as well, but Docker's context is bounded.
# Assuming the docker-compose context is the root of the project, we can copy the parent.
# But wait, this Dockerfile is specifically inside `examples/demo_app/`.
# Let's adjust to build locally inside the container assuming standard structure.

# Let's fetch deps. Since it path-depends on `../../`, we must build with the context at the project root!
# The COPY commands assume the build context is `/Users/jon/projects/parapet`
COPY mix.exs mix.lock ./
COPY lib/ ./lib/
COPY priv/ ./priv/
# We need to compile the parent library first so the demo app can depend on it
RUN mix deps.get && mix compile

# Now move to the demo app
WORKDIR /app/examples/demo_app

# Copy demo app dep files
COPY examples/demo_app/mix.exs examples/demo_app/mix.lock ./

# Fetch demo app dependencies
RUN mix deps.get

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
