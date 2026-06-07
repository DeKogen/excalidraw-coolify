# Coolify setup

The examples use `draw.example.com` and `draw-room.example.com`. Replace them
with real domains everywhere.

## 1. Configure DNS

Create two DNS `A` records pointing to the public IP address of the Ubuntu
24.04 VDS:

| Name | Value |
| --- | --- |
| `draw` | VDS public IP |
| `draw-room` | VDS public IP |

Wait until both names resolve to the VDS. When using Cloudflare, use **DNS
only** during initial troubleshooting.

## 2. Create the Coolify resource

1. In Coolify, create a new **Resource**.
2. Select **Docker Compose**.
3. Connect this Git repository.
4. Set the Compose file path to `docker-compose.yml`.

## 3. Add environment variables

Add these variables to the resource:

```dotenv
EXCALIDRAW_URL=https://draw.example.com
EXCALIDRAW_ROOM_URL=https://draw-room.example.com
```

`EXCALIDRAW_ROOM_URL` is used by the frontend startup patch. Keep the `https://`
scheme and do not add a trailing slash or a `/socket`, `/socket.io`, or `/ws`
path. Socket.IO adds its own `/socket.io/` path when the browser connects.

## 4. Assign domains

In the Coolify UI, assign each domain to the matching Compose service and its
internal port `80`:

| Service | Domain | Internal port |
| --- | --- | --- |
| `excalidraw` | `https://draw.example.com` | `80` |
| `excalidraw-room` | `https://draw-room.example.com` | `80` |

Do not add Caddy, nginx, Traefik labels, custom networks, or host port mappings.
Coolify's proxy handles routing, TLS, and WebSocket forwarding.

## 5. Deploy and verify

1. Deploy the resource.
2. Confirm both services are running in Coolify.
3. Open `https://draw.example.com` and confirm the certificate is valid.
4. Open `https://draw-room.example.com`; an unremarkable HTTP response is
   acceptable because its main purpose is WebSocket traffic.
5. Start live collaboration in Excalidraw.
6. Open the generated room link in a second browser or private window.
7. Confirm changes synchronize both ways.
8. In DevTools, open **Network** and filter by **WS**. Confirm the connection
   looks similar to
   `wss://draw-room.example.com/socket.io/?EIO=4&transport=websocket`.

If deployment works but collaboration does not, continue with
[troubleshooting.md](troubleshooting.md).

## After deploy

Open the Coolify resource and confirm both Compose services show as running:

- `excalidraw`
- `excalidraw-room`

Use the service-specific logs in the Coolify resource view:

- inspect `excalidraw` logs for frontend startup, `sed`, permission, or nginx
  errors;
- inspect `excalidraw-room` logs for startup and Socket.IO connection errors;
- inspect Coolify proxy logs for routing, TLS, or Bad Gateway errors.

In Coolify's domain configuration, select the specific service before assigning
each domain:

| Service | Domain |
| --- | --- |
| `excalidraw` | `https://draw.example.com` |
| `excalidraw-room` | `https://draw-room.example.com` |

The environment value must be the room backend base URL:

```dotenv
EXCALIDRAW_ROOM_URL=https://draw-room.example.com
```

Do not use:

```text
https://draw-room.example.com/socket
https://draw-room.example.com/socket.io
https://draw-room.example.com/ws
```

Then complete [post-deploy-checklist.md](post-deploy-checklist.md). The
command-line check does not require Docker:

```bash
EXCALIDRAW_URL=https://draw.example.com \
EXCALIDRAW_ROOM_URL=https://draw-room.example.com \
bash scripts/check-deploy.sh
```
