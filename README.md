# Excalidraw with live collaboration through Cloudflare Tunnel

Minimal Docker Compose stack for a self-hosted Excalidraw frontend, the
official `excalidraw-room` collaboration server, and Cloudflare Tunnel.

Cloudflare Tunnel provides public HTTPS routing without publishing host ports.
The existing Amnezia/Xray service keeps TCP port `443`; this stack does not
stop, reconfigure, or share that port. Inbound TCP ports `80` and `443` are not
required for Excalidraw.

## Architecture

- `excalidraw`: static Excalidraw frontend served by nginx.
- `excalidraw-room`: WebSocket collaboration backend.
- `cloudflared`: outbound tunnel connection to Cloudflare.
- `https://draw.deservin8.com`: routes to `http://excalidraw:80`.
- `https://draw-room.deservin8.com`: routes to `http://excalidraw-room:80`.

One frontend and one room server can serve many independent collaboration
rooms. Ten boards do not require ten containers. Each board is represented by
its own live collaboration URL containing a distinct `#room=...` fragment.

## How to use boards

A board is a saved live collaboration room link:

```text
https://draw.deservin8.com/#room=...
```

For ten boards, create and save ten room links. Do not create ten containers or
ten Excalidraw instances. Keep the links in a private `boards.md`; use
[boards.example.md](boards.example.md) as a starting point.

Self-hosted Excalidraw with `excalidraw-room` is not a full server-side board
storage or document-management system like Miro or Notion. The room server
coordinates encrypted live collaboration; it is not a durable board catalogue
or backup service.

For important boards, periodically use **Export** and save an `.excalidraw`
file in a backed-up location.

## Runtime collaboration URL patch

The official frontend image is already built. Setting
`VITE_APP_WS_SERVER_URL` at container runtime alone does not rebuild its
JavaScript. On startup, this stack replaces the built-in
`https://oss-collab.excalidraw.com` URL in compiled JavaScript files with
`EXCALIDRAW_ROOM_URL`, then starts nginx.

The Compose command uses `$${VITE_APP_WS_SERVER_URL}` deliberately: Docker
Compose converts `$$` to `$`, leaving the variable for the container shell to
expand at startup.

`EXCALIDRAW_ROOM_URL` must be the base URL without `/socket`, `/socket.io`, or
`/ws`:

```dotenv
EXCALIDRAW_ROOM_URL=https://draw-room.deservin8.com
```

The Socket.IO client adds its own path. A normal browser connection therefore
looks similar to
`wss://draw-room.deservin8.com/socket.io/?EIO=4&transport=websocket`.

## Deploy

1. Follow [docs/cloudflare-tunnel-setup.md](docs/cloudflare-tunnel-setup.md).
2. Copy `.env.example` to `.env` and replace the placeholder tunnel token.
3. Validate and start the stack using
   [docs/post-deploy-checklist.md](docs/post-deploy-checklist.md).
4. Use [docs/operations.md](docs/operations.md) for routine maintenance.
5. Use [docs/troubleshooting.md](docs/troubleshooting.md) when deployment or
   collaboration fails.

## Post-deploy quick test

1. Open `https://draw.deservin8.com` in one browser.
2. Click **Live collaboration**, start a session, and copy the generated room
   link.
3. Open that link in a private window or a second browser.
4. Draw in both windows and confirm changes synchronize both ways.
5. Open **DevTools → Network → WS** and confirm the WebSocket host is
   `draw-room.deservin8.com`.

A correct connection normally starts with
`wss://draw-room.deservin8.com/socket.io/`. Its host must not be
`oss-collab.excalidraw.com`.

Follow the complete [post-deploy checklist](docs/post-deploy-checklist.md) and
optionally run:

```bash
EXCALIDRAW_URL=https://draw.deservin8.com \
EXCALIDRAW_ROOM_URL=https://draw-room.deservin8.com \
bash scripts/check-deploy.sh
```

Where Docker daemon access is available, verify the compiled frontend patch:

```bash
bash scripts/check-runtime-patch.sh
```

## Local Compose validation

Create `.env` from `.env.example`, insert the Cloudflare Tunnel token, then
validate without starting containers:

```bash
docker compose --env-file .env config -q
```

`scripts/check-deploy.sh` does not require Docker. `scripts/check-runtime-patch.sh`
requires access to the Docker daemon and a running Compose stack.

## Known caveats

- The frontend uses `latest`; every redeploy that pulls a newer image must be
  followed by the two-browser collaboration and DevTools WS checks.
- The runtime patch depends on the upstream bundle containing the exact
  `https://oss-collab.excalidraw.com` string.
- The Cloudflare named tunnel and both Public Hostnames must be configured
  before the public URLs work.
- The token is a secret. Keep it only in the ignored `.env` file and rotate it
  if it is exposed.
- `excalidraw-room` is pinned to the known immutable `sha-03ff435` tag. The
  official image is old and provides collaboration transport, not durable
  storage.
- The stack has no application database or persistent board storage. Exported
  `.excalidraw` files are the meaningful board backups.
