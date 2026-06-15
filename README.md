# Wetfish IRC Network

Self-contained IRC network runnable locally via Docker Compose (single-host) or across multiple Kubernetes clusters (multi-DC).

```
┌─ Docker Compose (local) ──────────────────────────────────────────────────┐
│  hub.wetfish.local:6667 ←── leaf1:6668  ←── leaf2:6669                    │
│  3 nodes over spanningtree + The Lounge web client on :9000               │
└───────────────────────────────────────────────────────────────────────────┘

┌─ k3s Multi-DC (POC) ─────────────────────────────────────────────────────┐
│                                                                          │
│  ┌─ dc-us ─────────────────────┐    ┌─ dc-eu ─────────────────────┐      │
│  │  hub-us  ←── leaf-us-1      │    │  hub-eu  ←── leaf-eu-1      │      │
│  │          ←── leaf-us-2      │←──→│          ←── leaf-eu-2      │      │
│  │          ←── leaf-us-3      │    │          ←── leaf-eu-3      │      │
│  │  :30667 / :30700 (s2s)      │    │  :31667 / :31700 (s2s)      │      │
│  └─────────────────────────────┘    └─────────────────────────────┘      │
│                     Global: 8 servers (2 hubs + 6 leaves)                │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Local Docker Compose

Quick single-host IRC network for development.

### Run

```bash
./start.sh     # starts Docker, brings up 3 IRC nodes + The Lounge
./logs.sh      # tail all container logs
./stop.sh      # teardown
```

### Services

| Service | Host Port | Description |
|---------|-----------|-------------|
| `hub` (hub.wetfish.local) | `6667` | Central hub — leaves + The Lounge connect here |
| `leaf1` (leaf1.wetfish.local) | `6668` | Leaf 1 — autoconnects to hub |
| `leaf2` (leaf2.wetfish.local) | `6669` | Leaf 2 — autoconnects to hub |
| `thelounge` | `9000` | Web IRC client → `http://localhost:9000` |

### Configuration

Config files live under `inspircd/conf/`. A `common.conf` is shared across hub/leaves via `<include file="common.conf">` to eliminate duplication.

TLS certs can be generated locally (see [Secrets](#secrets)) and placed in `inspircd/conf/` — the image auto-generates self-signed certs on startup if none are found.

---

## k3s Multi-DC POC

Proof-of-concept deploying the IRC network across two Kubernetes clusters (simulating US and EU data centres). Each cluster runs its own control plane with a hub and 3 leaf nodes. Hubs are linked across clusters via spanningtree over NodePort services.

### Architecture

| Cluster | Namespace | Nodes | Client Port | S2S Port |
|---------|-----------|-------|-------------|----------|
| `k3d-dc-us` | `dc-us` | hub-us + leaf-us-{1,2,3} | `localhost:30667` | `localhost:30700` |
| `k3d-dc-eu` | `dc-eu` | hub-eu + leaf-eu-{1,2,3} | `localhost:31667` | `localhost:31700` |

- **8 IRC servers total** across 2 k3d clusters
- Hubs mesh-bidirectional with `<autoconnect>` (10s reconnect)
- Leaves autoconnect to their local hub via cluster DNS (`hub-us.dc-us.svc.cluster.local:7000`)
- Cross-DC hub link traverses Docker bridge network via NodePort (simulates WAN)

### Prerequisites

```bash
brew install k3d kubectl    # macOS
```

### Run

```bash
cd k3s-poc
./deploy.sh       # ~2-3 min: creates clusters, deploys all 8 servers
./teardown.sh     # destroys everything
```

### Verified

| Test | Result |
|------|--------|
| US Hub accepts IRC clients | ✓ |
| EU Hub accepts IRC clients | ✓ |
| Cross-DC server link (hub-us ←→ hub-eu) | ✓ |
| Message propagation US → EU | ✓ |
| Message propagation EU → US | ✓ |
| Leaves autoconnect to local hub (3 per DC) | ✓ |
| Global server count = 8 | ✓ |
| MOTD delivered across DCs | ✓ |

### Inspect

```bash
# Pod status
kubectl --context k3d-dc-us -n dc-us get pods,svc
kubectl --context k3d-dc-eu -n dc-eu get pods,svc

# Cross-DC link logs
kubectl --context k3d-dc-eu -n dc-eu logs deploy/hub-eu

# Connect an IRC client
irc://localhost:30667   # US hub
irc://localhost:31667   # EU hub
```

---

## Key Design Decisions

- **common.conf extraction** — 80 lines of duplicated inspircd config consolidated into a single `<include file="common.conf">` shared by all servers
- **stdout + file logging** — all IRC servers log to both file and stdout for Docker/K8s log aggregation
- **Health checks** — Docker Compose services use native health checks; k3s pods use readiness probes
- **Image pinning** — `inspircd/inspircd-docker:3` and `thelounge/thelounge:4` for reproducible builds
- **Secrets excluded from git** — TLS keys and VAPID keys are gitignored; generate locally

## Secrets

```bash
# Generate self-signed TLS certs for inspircd
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout inspircd/conf/key.pem \
  -out inspircd/conf/cert.pem \
  -days 365 -subj "/CN=irc.wetfish.local"
openssl dhparam -out inspircd/conf/dhparams.pem 2048

# Generate VAPID keys for The Lounge (web push)
npx -y web-push generate-vapid-keys --json > thelounge/conf/vapid.json
```

## File Tree

```
.
├── docker-compose.yml          # Single-host deployment
├── start.sh / stop.sh / logs.sh
├── inspircd/
│   └── conf/
│       ├── common.conf         # Shared config (hub + leaves)
│       ├── hub.conf            # Hub-specific (links to leaves)
│       ├── leaf1.conf          # Leaf 1 (autoconnect → hub)
│       ├── leaf2.conf          # Leaf 2
│       └── motd.txt
└── k3s-poc/
    ├── deploy.sh / teardown.sh
    └── configs/
        ├── common.conf
        └── motd.txt
```
