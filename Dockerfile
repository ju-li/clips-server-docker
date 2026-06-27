# syntax=docker/dockerfile:1

##############################################################################
# Builder — scaffold a standalone Clips instance, install deps, build Nitro
##############################################################################
FROM node:22-slim AS builder

# Non-interactive scaffolding + corepack without download prompts
ENV CI=true
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# Native build deps for any node-gyp modules pulled in during install
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# pnpm is provided via corepack (version pinned by the scaffold's package.json)
RUN corepack enable

WORKDIR /build

# Override to pin the template generator: --build-arg CORE_VERSION=1.2.3
ARG CORE_VERSION=latest

# Scaffold the app (creates /build/app), then install + build
RUN npx --yes @agent-native/core@${CORE_VERSION} create app --standalone --template clips

WORKDIR /build/app
RUN pnpm install
RUN pnpm build

##############################################################################
# Runner — minimal image, Nitro .output is self-contained
##############################################################################
FROM node:22-slim AS runner

ENV NODE_ENV=production
# Nitro binds NITRO_HOST/NITRO_PORT (falls back to PORT). Railway injects PORT.
ENV NITRO_HOST=0.0.0.0

WORKDIR /app

# Run as the unprivileged user shipped in the node image
COPY --from=builder --chown=node:node /build/app/.output ./.output
USER node

# Documentation only — Railway routes to the runtime $PORT, not this value
EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]
