# docker-socat-socks5h

TCP forwarding through SOCKS5h (Tor-compatible) using Docker, socat, and proxychains on Debian Slim.

This Docker image provides a minimal TCP proxy that forwards traffic through a SOCKS5h proxy, allowing remote hostname resolution over the proxy. It is well-suited for routing traffic through Tor or Shadowsocks.

## Features

- Based on debian:bookworm-slim.
- Uses socat for TCP port forwarding.
- Uses proxychains for SOCKS5h proxy support (DNS over proxy).
- Lightweight and minimal — no unnecessary packages.

## Usage

### Basic Example

```bash
docker run --rm \
  -e LISTEN_PORT=12345 \
  -e TARGET_HOST=example.com \
  -e TARGET_PORT=80 \
  -e SOCKS5H_HOST=127.0.0.1 \
  -e SOCKS5H_PORT=9050 \
  -p 12345:12345 \
  ghcr.io/jordimock/docker-socat-socks5h:latest
```

This starts a container that listens on port 12345 and forwards incoming connections to example.com:80 via the SOCKS5h proxy at 127.0.0.1:9050.

### Without Proxy

If you omit `SOCKS5H_HOST`, the traffic will go directly without proxying:

```bash
docker run --rm \
  -e LISTEN_PORT=12345 \
  -e TARGET_HOST=example.com \
  -e TARGET_PORT=80 \
  -p 12345:12345 \
  ghcr.io/jordimock/docker-socat-socks5h:latest
```

### With Docker Compose

```yaml
version: "3"
services:
  socat-proxy:
    image: ghcr.io/jordimock/docker-socat-socks5h:latest
    ports:
      - "12345:12345"
    environment:
      - LISTEN_PORT=12345
      - TARGET_HOST=example.com
      - TARGET_PORT=443
      - SOCKS5H_HOST=127.0.0.1
      - SOCKS5H_PORT=9050
```

## Environment Variables

| Variable        | Description                           | Required | Example         |
|-----------------|---------------------------------------|----------|-----------------|
| LISTEN_PORT     | Local port to expose inside container | Yes      | 12345           |
| TARGET_HOST     | Remote hostname to connect to         | Yes      | example.com     |
| TARGET_PORT     | Remote port to connect to             | Yes      | 80              |
| SOCKS5H_HOST    | SOCKS5h proxy host                    | No       | 127.0.0.1       |
| SOCKS5H_PORT    | SOCKS5h proxy port                    | No       | 9050            |


## License

Licensed under the Prostokvashino License. See [LICENSE.txt](LICENSE.txt) for details.