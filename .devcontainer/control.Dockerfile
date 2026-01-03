FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Ansible and Docker CLI
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository --yes --update ppa:ansible/ansible \
    && apt-get install -y \
    ansible \
    curl \
    git \
    iputils-ping \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (useful even though we use DnD feature for the daemon)
RUN curl -fsSL https://get.docker.com | sh

# Set the entrypoint to keep the container running
CMD ["/bin/sh", "-c", "while sleep 1000; do :; done"]
