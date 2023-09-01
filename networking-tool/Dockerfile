FROM ubuntu:latest

# Install networking tools
RUN apt-get update && apt-get install -y \
    dnsutils \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

CMD [ "bash" ]