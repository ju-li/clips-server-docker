# clips-server-docker

Railway-deployable Docker image for an [Agent-Native](https://github.com/agent-native) **Clips** server.

The image scaffolds a standalone Clips instance at build time, installs its dependencies, and builds the [Nitro](https://nitro.build) server. The resulting runtime image ships only the self-contained `.output` directory.

## How it works

Two-stage build:

- **builder** (`node:22-slim`) — scaffolds the app with `@agent-native/core create app --standalone --template clips`, then runs `pnpm install` and `pnpm build`.
- **runner** (`node:22-slim`) — copies the Nitro `.output` and runs it as the unprivileged `node` user.

## Build

```bash
docker build -t clips-server .
```

Pin the template generator version with a build arg (defaults to `latest`):

```bash
docker build --build-arg CORE_VERSION=1.2.3 -t clips-server .
```

## Run

```bash
docker run -p 3000:3000 clips-server
```

The server starts via `node .output/server/index.mjs`.

## Configuration

| Variable | Default | Notes |
| --- | --- | --- |
| `PORT` | `3000` | Nitro listen port. Railway injects this automatically. |
| `NITRO_HOST` | `0.0.0.0` | Bind address. |
| `NITRO_PORT` | — | Overrides `PORT` if set. |
| `NODE_ENV` | `production` | Set in the runner stage. |

## Deploy on Railway

Railway builds the `Dockerfile` directly and routes traffic to the runtime `$PORT`. No extra configuration is required — the `EXPOSE 3000` line is documentation only.
