#!/usr/bin/env sh
set -e

# Required
: "${LISTEN_PORT:?Missing LISTEN_PORT}"
: "${TARGET_HOST:?Missing TARGET_HOST}"
: "${TARGET_PORT:?Missing TARGET_PORT}"

if [ -n "${SOCKS5H_HOST:-}" ]; then
  : "${SOCKS5H_PORT:=1080}"

  echo "[INFO] Starting socat via proxychains (socks5h without auth)"
  echo "[INFO] SOCKS5 proxy (with DNS): $SOCKS5H_HOST:$SOCKS5H_PORT"
  echo "[INFO] Target:       $TARGET_HOST:$TARGET_PORT"
  echo "[INFO] Listening on: 0.0.0.0:$LISTEN_PORT"

  {
    echo "logoutput: stderr"
    echo "internal: 127.0.0.1 port = 1080"
    echo "external: eth0"
    echo "socksmethod: none"
    echo "user.privileged: root"
    echo "user.unprivileged: nobody"
    echo "user.libwrap: nobody"
    echo ""
    echo "client pass {"
    echo "  from: 127.0.0.1/32 to: 0.0.0.0/0"
    echo "  log: connect disconnect error"
    echo "}"
    echo ""
    echo "socks pass {"
    echo "  from: 127.0.0.1/32 to: 0.0.0.0/0"
    echo "  protocol: tcp udp"
    echo "  log: connect disconnect error"
    echo "}"
  } >/etc/danted.conf
  {
    echo "strict_chain"
    echo "proxy_dns"
    echo "tcp_read_time_out 15000"
    echo "tcp_connect_time_out 8000"
    echo "[ProxyList]"
    echo "socks5 127.0.0.1 1080"
    echo "socks5  ${SOCKS5H_HOST} ${SOCKS5H_PORT}
  } >/etc/proxychains4.conf

  {
    echo "[supervisord]"
    echo "nodaemon=true"
    echo "logfile=/dev/stdout"
    echo "logfile_maxbytes=0"
    echo ""
    echo "[program:danted]"
    echo "command=bash -c '/usr/sbin/danted -f /etc/danted.conf && kill -s SIGINT \$(cat supervisord.pid) || kill -s SIGINT \$(cat supervisord.pid)'"
    echo "stopasgroup = true"
    echo "autorestart=false"
    echo "stdout_logfile=/dev/stdout"
    echo "stdout_logfile_maxbytes=0"
    echo "stderr_logfile=/dev/stderr"
    echo "stderr_logfile_maxbytes=0"
    echo ""
    echo "[program:proxychains-socat]"
    echo "command=bash -c '/usr/bin/proxychains4 /usr/bin/socat TCP-LISTEN:${LISTEN_PORT},fork,reuseaddr TCP:${TARGET_HOST}:${TARGET_PORT} && kill -s SIGINT \$(cat supervisord.pid) || kill -s SIGINT \$(cat supervisord.pid)'"
    echo "stopasgroup = true"
    echo "autorestart=false"
    echo "stdout_logfile=/dev/stdout"
    echo "stdout_logfile_maxbytes=0"
    echo "stderr_logfile=/dev/stderr"
    echo "stderr_logfile_maxbytes=0"
  } >/etc/supervisord.conf

  exec /usr/bin/supervisord -c /etc/supervisord.conf

else
  echo "[INFO] Starting socat directly (no proxy)..."
  echo "[INFO] Target:       $TARGET_HOST:$TARGET_PORT"
  echo "[INFO] Listening on: 0.0.0.0:$LISTEN_PORT"

  exec socat TCP-LISTEN:$LISTEN_PORT,fork,reuseaddr TCP:$TARGET_HOST:$TARGET_PORT
fi
