#!/usr/bin/env sh
set -e

# Required
: "${LISTEN_PORT:?Missing LISTEN_PORT}"
: "${TARGET_HOST:?Missing TARGET_HOST}"
: "${TARGET_PORT:?Missing TARGET_PORT}"

if [ -n "${SOCKS5H_HOST:-}" ]; then
  : "${SOCKS5H_PORT:=1080}"
  : "${SOCKS5H_USER:?Missing SOCKS5H_USER}"
  : "${SOCKS5H_PASSWORD:?Missing SOCKS5H_PASSWORD}"

  echo "[INFO] Starting socat via proxychains (socks5h with auth)"
  echo "[INFO] SOCKS5 proxy (with DNS): $SOCKS5H_HOST:$SOCKS5H_PORT"
  echo "[INFO] Proxy user: $SOCKS5H_USER"
  echo "[INFO] Target:       $TARGET_HOST:$TARGET_PORT"
  echo "[INFO] Listening on: 0.0.0.0:$LISTEN_PORT"

  {
    echo "strict_chain"
    echo "proxy_dns"
    echo "tcp_read_time_out 15000"
    echo "tcp_connect_time_out 8000"
    echo "[ProxyList]"
    echo "socks5  ${SOCKS5H_HOST} ${SOCKS5H_PORT} ${SOCKS5H_USER} ${SOCKS5H_PASSWORD}"
  } > /etc/proxychains.conf

  exec proxychains socat TCP-LISTEN:$LISTEN_PORT,fork,reuseaddr TCP:$TARGET_HOST:$TARGET_PORT

else
  echo "[INFO] Starting socat directly (no proxy)..."
  echo "[INFO] Target:       $TARGET_HOST:$TARGET_PORT"
  echo "[INFO] Listening on: 0.0.0.0:$LISTEN_PORT"

  exec socat TCP-LISTEN:$LISTEN_PORT,fork,reuseaddr TCP:$TARGET_HOST:$TARGET_PORT
fi
