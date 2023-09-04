FROM ubuntu:latest

# Avoid prompts with apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Install networking tools
RUN apt-get update && apt-get install -y \
    dnsutils \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Keep the container running
CMD ["tail", "-f", "/dev/null"]