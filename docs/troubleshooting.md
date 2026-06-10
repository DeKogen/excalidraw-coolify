# Troubleshooting

## Symptom 1: Frontend opens, but live collaboration does not work

1. Open browser DevTools.
2. Select **Network** and filter by **WS**.
3. Start or join a collaboration session.
4. Confirm the WebSocket connection looks similar to
   `wss://draw-room.deservin8.com/socket.io/?EIO=4&transport=websocket`.

If it connects to `oss-collab.excalidraw.com`, the runtime patch did not apply.
Inspect `excalidraw` startup logs, verify `EXCALIDRAW_ROOM_URL`, and redeploy.
The environment value itself must remain the base URL
`https://draw-room.deservin8.com`; do not append `/socket`, `/socket.io`, or
`/ws`.

If the WebSocket host is `draw-room.deservin8.com` but the connection fails,
inspect `excalidraw-room`, `cloudflared`, and the Cloudflare Tunnel route.

Where Docker daemon access is available, run:

```bash
bash scripts/check-runtime-patch.sh
```

## Symptom 2: `cloudflared` does not connect

- Confirm `.env` contains a real `CLOUDFLARE_TUNNEL_TOKEN`.
- Confirm the token belongs to the intended active tunnel.
- Run `docker compose logs cloudflared`.
- Confirm the VDS has outbound network access.

## Symptom 3: Public hostname does not open

- Confirm the tunnel connector is healthy in Cloudflare Zero Trust.
- Confirm the Public Hostname service is exactly `http://excalidraw:80` or
  `http://excalidraw-room:80`.
- Check `docker compose ps` and `docker compose logs cloudflared`.
- Confirm DNS does not still contain an `A` record pointing `draw` or
  `draw-room` to `87.120.36.167`. The tunnel should manage CNAME routes.

## Symptom 4: Socket.IO polling endpoint does not return a handshake

Run:

```bash
curl -fsS 'https://draw-room.deservin8.com/socket.io/?EIO=4&transport=polling'
```

A successful response starts with a Socket.IO open packet similar to
`0{"sid":...}`.

If it fails:

- confirm `EXCALIDRAW_ROOM_URL` is the base URL without `/socket`,
  `/socket.io`, or `/ws`;
- confirm the tunnel route maps to `http://excalidraw-room:80`;
- inspect `excalidraw-room` and `cloudflared` logs;
- confirm Cloudflare WebSockets are enabled.

You can run all command-line deployment checks with
`bash scripts/check-deploy.sh`.

## Symptom 5: Two windows show different boards

- Confirm both windows opened the exact same complete `#room=...` link.
- Confirm the room link was not truncated by chat, email, or a password
  manager.
- Confirm both links use the same frontend domain:
  `https://draw.deservin8.com`.
- Copy the room link directly from one working window and open it in the other.

## WebSocket errors

- Confirm `https://draw-room.deservin8.com` is reachable through the tunnel.
- Confirm both frontend and room domains use HTTPS; otherwise the browser may
  block mixed content.
- Confirm `EXCALIDRAW_ROOM_URL` has no custom path. Socket.IO adds
  `/socket.io/` automatically.
- Confirm Cloudflare WebSockets are enabled.
- Inspect the browser console, WS response, room-service logs, and cloudflared
  logs.

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
  --build-arg VITE_APP_WS_SERVER_URL=https://draw-room.deservin8.com \
  -t registry.example.com/excalidraw:your-version .
docker push registry.example.com/excalidraw:your-version
```

Pin that custom image tag or digest in Compose, then remove the frontend
runtime `environment`, `entrypoint`, and `command`.

Build-time configuration is more predictable, but it adds an image build and
release process. Keep the runtime patch while it remains covered by the
post-deploy WS check.
