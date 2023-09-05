FROM ubuntu:latest

# Install networking tools
RUN apt-get update && apt-get install -y \
    dnsutils \
    iputils-ping \
    net-tools \
    traceroute \
    iputils-tracepath \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Keep the container running
ENTRYPOINT ["tail", "-f", "/dev/null"]