# Operations

## Update the stack

Before updating, export important boards as `.excalidraw` files.

1. Review upstream Excalidraw and `excalidraw-room` changes.
2. Pull updated images with `docker compose --env-file .env pull`.
3. Recreate the stack with `docker compose --env-file .env up -d`.
4. After deployment, test a room from two browser sessions.
5. In DevTools **Network → WS**, confirm the room host is still your
   `draw-room` domain.

The frontend uses `latest`, which makes its updates less predictable. The room
service is pinned to `sha-03ff435`. For controlled production changes, pin
tested frontend image digests too and commit each image change.

## Roll back

1. Revert `docker-compose.yml` to the previous tested image tags or digests.
2. Redeploy the previous Git revision with Docker Compose.
3. Retest HTTPS and live collaboration.

Room links and room-server state are not a substitute for exported board
files. A rollback cannot recover a board that was never exported.

## Logs

Use Docker Compose to inspect logs separately:

- `excalidraw`: nginx startup errors and runtime patch failures.
- `excalidraw-room`: room server startup and WebSocket connection errors.
- `cloudflared`: tunnel authentication, routing, and upstream errors.

The frontend startup log should not contain `find`, `sed`, permission, or nginx
errors.

## Organize 10+ boards

Copy `boards.example.md` to a private `boards.md` and record one collaboration
room link per board. Group links by project or team when the list grows.

Treat room URLs as secrets: anyone with a room link and its embedded key may be
able to join. Do not commit a real `boards.md` to a public repository.

## Export important boards

For each important board, periodically use **Export → Export to
`.excalidraw`** and store the file in a backed-up location. Export after major
planning sessions or before upgrades.

## Backups that matter

Back up:

- exported `.excalidraw` files;
- the private board-link catalogue;
- this repository and pinned deployment revisions;
- Cloudflare Tunnel hostname configuration and the safely stored tunnel token.

There is no application database or persistent volume in this minimal stack.
Backing up the stateless frontend container is not useful. Do not treat the
ephemeral room server as durable board storage.
