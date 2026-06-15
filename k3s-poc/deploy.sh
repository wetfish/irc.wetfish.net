#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*" >&2; }

NETWORK="irc-net"
S2S_PASS="hub2hub"

# ── Prerequisites ──────────────────────────────────────────────
check_prereqs() {
  local missing=()
  for cmd in docker k3d kubectl; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    err "Missing: ${missing[*]}"
    echo "  Install k3d:   brew install k3d"
    echo "  Install kubectl: brew install kubectl"
    exit 1
  fi
}

# ── Network ────────────────────────────────────────────────────
create_network() {
  if docker network inspect "$NETWORK" &>/dev/null; then
    info "Docker network '$NETWORK' already exists"
  else
    info "Creating Docker network: $NETWORK"
    docker network create "$NETWORK"
  fi
}

# ── Cluster ────────────────────────────────────────────────────
create_cluster() {
  local name="$1" irchost="$2" s2shost="$3"

  if k3d cluster list 2>/dev/null | grep -q "$name"; then
    warn "Cluster '$name' already exists, skipping"
    return
  fi

  info "Creating k3d cluster: $name (irc=$irchost s2s=$s2shost)"
  k3d cluster create "$name" \
    --network "$NETWORK" \
    -p "${irchost}:${irchost}@server:0" \
    -p "${s2shost}:${s2shost}@server:0" \
    --k3s-arg "--disable=traefik@server:0" \
    --k3s-arg "--disable=servicelb@server:0" \
    --wait
}

get_cluster_ip() {
  docker inspect "k3d-${1}-server-0" \
    --format "{{(index .NetworkSettings.Networks \"${NETWORK}\").IPAddress}}"
}

wait_for_cluster() {
  info "Waiting for cluster $1..."
  kubectl --context "k3d-$1" wait --for=condition=ready node --all --timeout=120s
}

# ── IRC Config generation ─────────────────────────────────────
deploy_dc() {
  local ctx="$1" ns="$2" hub_name="$3" leaf_prefix="$4"
  local remote_ip="$5" remote_port="$6" remote_name="$7"

  info "Deploying DC: $ns ($hub_name + 3 leaves)"

  # ── namespace ──
  kubectl --context "$ctx" create namespace "$ns" --dry-run=client -o yaml | kubectl --context "$ctx" apply -f -

  # ── common ConfigMap (shared by all IRC servers in this DC) ──
  kubectl --context "$ctx" -n "$ns" create configmap common-config \
    --from-file=common.conf="$SCRIPT_DIR/configs/common.conf" \
    --from-file=motd.txt="$SCRIPT_DIR/configs/motd.txt" \
    --dry-run=client -o yaml | kubectl --context "$ctx" apply -f -

  # ── hub config ──
  cat <<EOF | kubectl --context "$ctx" -n "$ns" create configmap hub-config \
    --from-file=inspircd.conf=/dev/stdin --dry-run=client -o yaml | kubectl --context "$ctx" apply -f -
<server
    name="${hub_name}.wetfish.local"
    description="Wetfish ${hub_name##*-} Hub"
    network="Wetfish">

<include file="common.conf">

<module name="spanningtree">

<link name="${leaf_prefix}-1.wetfish.local"
    ipaddr="${leaf_prefix}-1.${ns}.svc.cluster.local"
    port="7000"
    allowmask="*"
    sendpass="hub2leaf"
    recvpass="leaf2hub">

<link name="${leaf_prefix}-2.wetfish.local"
    ipaddr="${leaf_prefix}-2.${ns}.svc.cluster.local"
    port="7000"
    allowmask="*"
    sendpass="hub2leaf"
    recvpass="leaf2hub">

<link name="${leaf_prefix}-3.wetfish.local"
    ipaddr="${leaf_prefix}-3.${ns}.svc.cluster.local"
    port="7000"
    allowmask="*"
    sendpass="hub2leaf"
    recvpass="leaf2hub">

<link name="${remote_name}.wetfish.local"
    ipaddr="${remote_ip}"
    port="${remote_port}"
    allowmask="*"
    sendpass="${S2S_PASS}"
    recvpass="${S2S_PASS}">

<autoconnect period="10" server="${remote_name}.wetfish.local">
EOF

  # ── leaf configs ──
  for i in 1 2 3; do
    local leaf="${leaf_prefix}-${i}"
    cat <<EOF | kubectl --context "$ctx" -n "$ns" create configmap "${leaf}-config" \
      --from-file=inspircd.conf=/dev/stdin --dry-run=client -o yaml | kubectl --context "$ctx" apply -f -
<server
    name="${leaf}.wetfish.local"
    description="Wetfish ${leaf_prefix##*-} Leaf ${i}"
    network="Wetfish">

<include file="common.conf">

<module name="spanningtree">

<link name="${hub_name}.wetfish.local"
    ipaddr="${hub_name}.${ns}.svc.cluster.local"
    port="7000"
    allowmask="*"
    sendpass="leaf2hub"
    recvpass="hub2leaf">

<autoconnect period="10" server="${hub_name}.wetfish.local">
EOF
  done
}

# ── Kubernetes resources ──────────────────────────────────────
deploy_irc_server() {
  local ctx="$1" ns="$2" name="$3" configmap="$4"

  kubectl --context "$ctx" -n "$ns" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  labels:
    app: irc
    server: $name
spec:
  replicas: 1
  selector:
    matchLabels:
      app: irc
      server: $name
  template:
    metadata:
      labels:
        app: irc
        server: $name
    spec:
      containers:
        - name: inspircd
          image: inspircd/inspircd-docker:3
          ports:
            - containerPort: 6667
              name: irc
            - containerPort: 7000
              name: s2s
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
          volumeMounts:
            - name: config
              mountPath: /inspircd/conf/inspircd.conf
              subPath: inspircd.conf
            - name: common
              mountPath: /inspircd/conf/common.conf
              subPath: common.conf
            - name: common
              mountPath: /inspircd/conf/motd.txt
              subPath: motd.txt
      volumes:
        - name: config
          configMap:
            name: $configmap
        - name: common
          configMap:
            name: common-config
EOF
}

deploy_hub_svc() {
  local ctx="$1" ns="$2" name="$3" ircnode="$4" s2snode="$5"

  kubectl --context "$ctx" -n "$ns" apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $name
  labels:
    app: irc
    server: $name
spec:
  type: NodePort
  selector:
    server: $name
  ports:
    - name: irc
      port: 6667
      nodePort: $ircnode
    - name: s2s
      port: 7000
      nodePort: $s2snode
EOF
}

deploy_leaf_svc() {
  local ctx="$1" ns="$2" name="$3"

  kubectl --context "$ctx" -n "$ns" apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $name
  labels:
    app: irc
    server: $name
spec:
  type: ClusterIP
  selector:
    server: $name
  ports:
    - name: irc
      port: 6667
    - name: s2s
      port: 7000
EOF
}

# ── Main ───────────────────────────────────────────────────────
main() {
  check_prereqs
  create_network

  # ── Create two k3d clusters ──────────────────────────────
  # dc-us: irc NodePort 30667, S2S NodePort 30700
  # dc-eu: irc NodePort 31667, S2S NodePort 31700
  create_cluster "dc-us" 30667 30700
  create_cluster "dc-eu" 31667 31700

  wait_for_cluster "dc-us"
  wait_for_cluster "dc-eu"

  # ── Discover cross-cluster IPs ───────────────────────────
  local US_IP; US_IP=$(get_cluster_ip "dc-us")
  local EU_IP; EU_IP=$(get_cluster_ip "dc-eu")

  info "DC-US server IP on $NETWORK: $US_IP"
  info "DC-EU server IP on $NETWORK: $EU_IP"

  # ── Deploy configs (ConfigMaps) ──────────────────────────
  # Both hubs autoconnect to each other (bidirectional mesh)
  deploy_dc "k3d-dc-us" "dc-us" "hub-us" "leaf-us" "$EU_IP" 31700 "hub-eu"
  deploy_dc "k3d-dc-eu" "dc-eu" "hub-eu" "leaf-eu" "$US_IP" 30700 "hub-us"

  # ── Deploy hubs (Deployment + NodePort Service) ──────────
  deploy_irc_server "k3d-dc-us" "dc-us" "hub-us" "hub-config"
  deploy_irc_server "k3d-dc-eu" "dc-eu" "hub-eu" "hub-config"
  deploy_hub_svc    "k3d-dc-us" "dc-us" "hub-us" 30667 30700
  deploy_hub_svc    "k3d-dc-eu" "dc-eu" "hub-eu" 31667 31700

  # ── Deploy leaves (Deployment + ClusterIP Service) ──────
  for i in 1 2 3; do
    deploy_irc_server "k3d-dc-us" "dc-us" "leaf-us-${i}" "leaf-us-${i}-config"
    deploy_irc_server "k3d-dc-eu" "dc-eu" "leaf-eu-${i}" "leaf-eu-${i}-config"
    deploy_leaf_svc    "k3d-dc-us" "dc-us" "leaf-us-${i}"
    deploy_leaf_svc    "k3d-dc-eu" "dc-eu" "leaf-eu-${i}"
  done

  # ── Wait for readiness ──────────────────────────────────
  info "Waiting for all pods (this may take a minute)..."
  kubectl --context k3d-dc-us -n dc-us wait --for=condition=ready pod -l app=irc --timeout=180s
  kubectl --context k3d-dc-eu -n dc-eu wait --for=condition=ready pod -l app=irc --timeout=180s

  echo ""
  echo "══════════════════════════════════════════════════════════"
  info "Deploy complete!"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo "  Topology:"
  echo "    ┌─ DC-US ─────────────────────┐    ┌─ DC-EU ─────────────────────┐"
  echo "    │  hub-us ←── leaf-us-{1,2,3} │←──→│  hub-eu ←── leaf-eu-{1,2,3} │"
  echo "    └─────────────────────────────┘    └─────────────────────────────┘"
  echo ""
  echo "  Connect IRC client:"
  echo "    US Hub:   irc://localhost:30667   (→ hub-us)"
  echo "    EU Hub:   irc://localhost:31667   (→ hub-eu)"
  echo ""
  echo "  Inspect:"
  echo "    kubectl --context k3d-dc-us -n dc-us get pods,svc"
  echo "    kubectl --context k3d-dc-eu -n dc-eu get pods,svc"
  echo ""
  echo "  Logs (cross-DC link):"
  echo "    kubectl --context k3d-dc-eu -n dc-eu logs deploy/hub-eu"
  echo ""
  echo "  Tear down:"
  echo "    ./teardown.sh"
}

main "$@"
