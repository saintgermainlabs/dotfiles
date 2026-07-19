# Primordial stage — shared foundation for all Linux-management devcontainers.
# Software, bootstrap scripts, and build-time environment probe only.
# No vscode user, no role-specific tooling. Safe to reuse across devops/dotfiles/etc.
FROM ubuntu:24.04 AS primordial

ENV DEBIAN_FRONTEND=noninteractive

COPY scripts/ /opt/primordial/scripts/
COPY secrets/ /opt/primordial/secrets/
RUN chmod +x /opt/primordial/scripts/*.sh /opt/primordial/scripts/lib/*.sh \
    && bash /opt/primordial/scripts/install-primordial-packages.sh \
    && mkdir -p /var/lib/primordial \
    && bash /opt/primordial/scripts/probe-env.sh build-time

# Base stage — devcontainer runtime user and shared mounts.
FROM primordial AS base

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# ubuntu:24.04 ships a default 'ubuntu' user at UID/GID 1000 — replace it.
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupdel ubuntu 2>/dev/null || true \
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && mkdir -p /var/run/tailscale /var/lib/tailscale /var/lib/primordial \
    && mkdir -p /home/${USERNAME}/.ssh /home/${USERNAME}/.config/age \
    && chmod 700 /home/${USERNAME}/.ssh /home/${USERNAME}/.config/age \
    && chown -R ${USERNAME}:${USERNAME} /var/run/tailscale /var/lib/tailscale /var/lib/primordial /home/${USERNAME}/.ssh /home/${USERNAME}/.config

FROM base AS dotfiles

RUN apt-get update && apt-get install -y --no-install-recommends \
    lsb-release \
    python3-pip \
    python3-venv \
    unzip \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && env UV_TOOL_DIR=/usr/local/share/uv/tools UV_TOOL_BIN_DIR=/usr/local/bin \
       uv tool install --force --python python3.12 --with pip aider-chat@latest

USER ${USERNAME}
WORKDIR /workspaces/sgdotfilesfresh
