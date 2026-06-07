# Troubleshooting

## Symptom 1: Frontend opens, but live collaboration does not work

1. Open browser DevTools.
2. Select **Network** and filter by **WS**.
3. Start or join a collaboration session.
4. Confirm the WebSocket connection looks similar to
   `wss://draw-room.example.com/socket.io/?EIO=4&transport=websocket`.

If it connects to `oss-collab.excalidraw.com`, the runtime patch did not apply.
Inspect `excalidraw` startup logs, verify `EXCALIDRAW_ROOM_URL`, and redeploy.
The environment value itself must remain the base URL
`https://draw-room.example.com`; do not append `/socket`, `/socket.io`, or
`/ws`.

If the WebSocket host is `draw-room.example.com` but the connection fails,
inspect the `excalidraw-room` service, Coolify domain mapping, HTTPS
certificate, room-service logs, and Coolify proxy logs.

Where Docker daemon access is available, run:

```bash
bash scripts/check-runtime-patch.sh
```

## Symptom 2: `draw-room.example.com` returns Bad Gateway

- Confirm the `excalidraw-room` service is running.
- Confirm `https://draw-room.example.com` is assigned specifically to
  `excalidraw-room`.
- Confirm the service exposes internal port `80`.
- Inspect the `excalidraw-room` container logs and Coolify proxy logs.

The Compose file intentionally uses `expose: "80"` instead of a public host
port mapping.

## Symptom 3: Socket.IO polling endpoint does not return a handshake

Run:

```bash
curl -fsS 'https://draw-room.example.com/socket.io/?EIO=4&transport=polling'
```

A successful response starts with a Socket.IO open packet similar to
`0{"sid":...}`.

If it fails:

- confirm `EXCALIDRAW_ROOM_URL` is the base URL without `/socket`,
  `/socket.io`, or `/ws`;
- confirm the Coolify domain maps to `excalidraw-room` internal port `80`;
- confirm HTTPS is valid;
- inspect room-service and Coolify proxy logs.

You can run all command-line deployment checks with
`bash scripts/check-deploy.sh`.

## Symptom 4: Two windows show different boards

- Confirm both windows opened the exact same complete `#room=...` link.
- Confirm the room link was not truncated by chat, email, or a password
  manager.
- Confirm both links use the same frontend domain:
  `https://draw.example.com`.
- Copy the room link directly from one working window and open it in the other.

## HTTPS certificate is not issued

- Confirm both DNS records resolve to the VDS public IP.
- Confirm inbound TCP ports `80` and `443` are open in the VDS firewall and
  provider firewall.
- Confirm the domains are assigned correctly in Coolify.
- When using Cloudflare, temporarily switch the records to **DNS only** while
  diagnosing certificate issuance.

## WebSocket errors

- Confirm `https://draw-room.example.com` is reachable through Coolify.
- Confirm both frontend and room domains use HTTPS; otherwise the browser may
  block mixed content.
- Confirm `EXCALIDRAW_ROOM_URL` has no custom path. Socket.IO adds
  `/socket.io/` automatically.
- Confirm Coolify assigned the room domain to `excalidraw-room` port `80`.
- Inspect the browser console, WS request response, room-service logs, and
  Coolify proxy logs.

## After an update, Excalidraw uses the official collaboration server again

1. Inspect `excalidraw` startup logs for `find`, `sed`, or permission errors.
2. Verify `EXCALIDRAW_ROOM_URL` contains the intended HTTPS URL.
3. Redeploy the stack so the startup patch runs against the new bundle.
4. Clear the browser cache or test in a private window.
5. Check DevTools **Network → WS** again.

An upstream frontend release may change or remove the exact
`https://oss-collab.excalidraw.com` string. If the patch no longer finds it,
pin the last working image and use the custom-image fallback described below.

## Custom-image fallback

If runtime patching becomes unreliable, build a small custom frontend image
from a pinned upstream Excalidraw source revision and provide
`VITE_APP_WS_SERVER_URL` at build time. In a checkout of the upstream source,
add the build argument before its existing `yarn build:app:docker` step:

```dockerfile
ARG VITE_APP_WS_SERVER_URL
ENV VITE_APP_WS_SERVER_URL=${VITE_APP_WS_SERVER_URL}
RUN npm_config_target_arch=${TARGETARCH} yarn build:app:docker
```

Build and publish it with the real room URL:

```bash
docker build \
  --build-arg VITE_APP_WS_SERVER_URL=https://draw-room.example.com \
  -t registry.example.com/excalidraw:your-version .
docker push registry.example.com/excalidraw:your-version
```

Pin that custom image tag or digest in Compose, then remove the frontend
runtime `environment`, `entrypoint`, and `command`.

Build-time configuration is more predictable, but it adds an image build and
release process. Keep the runtime patch while it remains covered by the
post-deploy WS check.
