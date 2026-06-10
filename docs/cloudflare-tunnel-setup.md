# Cloudflare Tunnel setup

This deployment uses a named Cloudflare Tunnel. The `cloudflared` container
connects outbound to Cloudflare, so Excalidraw does not publish host ports and
does not interfere with Amnezia/Xray on TCP port `443`.

## 1. Create the tunnel

1. Open Cloudflare Zero Trust.
2. Go to **Networks -> Tunnels**.
3. Create a Cloudflared tunnel and give it a clear name, such as
   `excalidraw-vds`.
4. Choose the Docker connector instructions and copy the tunnel token.
5. Do not commit the token. Put it only in `/root/excalidraw-coolify/.env`.

Create `.env` from the example and replace only the placeholder token:

```bash
cd /root/excalidraw-coolify
cp .env.example .env
chmod 600 .env
```

## 2. Add Public Hostnames

Add these routes to the tunnel:

| Public hostname | Service |
| --- | --- |
| `draw.deservin8.com` | `http://excalidraw:80` |
| `draw-room.deservin8.com` | `http://excalidraw-room:80` |

The service names resolve through the default Docker Compose network shared by
all three containers.

If existing DNS `A` records for `draw` or `draw-room` point to
`87.120.36.167`, remove those records manually before creating the Public
Hostnames. Let Cloudflare Tunnel create and manage the corresponding CNAME
routes. Do not point these hostnames directly at the VDS.

## 3. Check WebSockets

Cloudflare normally supports WebSockets automatically. In the Cloudflare
Network settings, confirm WebSockets are enabled if collaboration connections
fail.

## 4. Validate before starting

```bash
docker compose --env-file .env config -q
```

Then follow [post-deploy-checklist.md](post-deploy-checklist.md). Starting the
stack does not bind host ports `80` or `443`.
