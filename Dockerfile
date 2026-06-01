# Find eligible builder and runner images on Docker Hub. We use Ubuntu 24.04 as
# the base image for both builder and runner.
FROM --platform=$BUILDPLATFORM elixir:1.18.1-erlang-27.2-ubuntu-24.04 AS base

# Set the locale
ENV LANG C.UTF-8

# Install required dependencies
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    nodejs \
    npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# --- Builder stage ---
FROM base AS builder

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set the MIX_ENV to prod for the build
ENV MIX_ENV=prod

# Install Mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy the remaining files
COPY priv priv
COPY lib lib

# Compile
RUN mix compile

# Install assets
RUN mix assets.setup

# Build assets
RUN mix assets.deploy

# Build release
RUN mix release

# --- Runner stage ---
FROM base AS runner

# Set the MIX_ENV to prod
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# Don't run production as root
RUN addgroup --system --gid 1000 jersey
RUN adduser --system --uid 1000 --ingroup jersey jersey
USER jersey

WORKDIR /app

# Copy the release from the builder stage
COPY --from=builder --chown=jersey:jersey /app/_build/prod/rel/jersey ./

# Set the release path
ENV RELEASE_SERVER=true

# Expose the port the app runs on
EXPOSE 4000

# Start the server
CMD ["bin/server"]
