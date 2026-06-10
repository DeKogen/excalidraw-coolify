# Post-deploy checklist

Use this checklist after the first Cloudflare Tunnel deployment and after every
frontend image update.

## Start and inspect the stack

```bash
cd /root/excalidraw-coolify
docker compose --env-file .env config -q
docker compose --env-file .env up -d
docker compose ps
docker compose logs -f cloudflared
```

The stack must not publish host ports.

Check the public endpoints:

```bash
curl -I https://draw.deservin8.com
curl -i "https://draw-room.deservin8.com/socket.io/?EIO=4&transport=polling"
```

## Open the frontend

Open:

```text
https://draw.deservin8.com
```

The Excalidraw interface should load over HTTPS.

## Create the first board

1. Open the frontend.
2. Click **Live collaboration**.
3. Click **Start session**.
4. Copy the generated link, which looks like
   `https://draw.deservin8.com/#room=...`.
5. Save the complete link in a private `boards.md`.

## Create 10+ boards

Repeat the live collaboration session creation process for every board. Each
board is a separate saved `#room=...` link.

Do not create separate containers or separate Excalidraw instances. The same
`excalidraw` frontend and `excalidraw-room` service handle many rooms.

## Test board synchronization

1. Open a complete room link in a normal browser window.
2. Open the same complete link in an incognito window or another browser.
3. Draw an object in the first window.
4. Confirm it appears in the second window.
5. Draw an object in the second window.
6. Confirm it appears in the first window.

## Check the WebSocket connection

In Chrome or Edge:

1. Open **DevTools → Network → WS**.
2. Start or join a live collaboration session.
3. Inspect the active WebSocket connection.

Expected address:

```text
wss://draw-room.deservin8.com/socket.io/?EIO=4&transport=websocket
```

An address starting with this host is wrong:

```text
wss://oss-collab.excalidraw.com/socket.io/...
```

That means the frontend runtime `sed` patch did not apply.

## Check from the command line

Run the HTTP and Socket.IO polling checks from any machine with `curl`:

```bash
EXCALIDRAW_URL=https://draw.deservin8.com \
EXCALIDRAW_ROOM_URL=https://draw-room.deservin8.com \
bash scripts/check-deploy.sh
```

The script cannot test browser-only collaboration synchronization. Always
complete the two-browser test.

## Room backend response

`https://draw-room.deservin8.com` does not need to display a polished page. It is
the room and WebSocket backend, not the Excalidraw frontend. A plain response
or `404` at its root can still mean the service is reachable; the Socket.IO
polling and two-browser tests are the useful checks.
