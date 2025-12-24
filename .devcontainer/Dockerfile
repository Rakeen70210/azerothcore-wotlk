FROM archlinux:latest AS dev

# Update system and install dependencies
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git wget && \
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key 3056513887B78AEB && \
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' && \
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf && \
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm \
    cmake \
    clang \
    ccache \
    gperftools \
    mysql \
    readline \
    ncurses \
    bzip2 \
    openssl \
    boost \
    gdb \
    curl \
    unzip \
    jq \
    screen \
    tmux \
    expect \
    python \
    sudo \
    vim \
    nano \
    lsb-release

# Create a user 'acore' to match the typical setup, or use root.
# The devcontainer setup often uses the user specified in devcontainer.json (root).
# But we might want to allow sudo for a non-root user if we switch.
# For now, we stick to root as per existing devcontainer.json "remoteUser": "root".

# Set up ccache
ENV PATH="/usr/lib/ccache/bin:${PATH}"

# Set working directory
WORKDIR /azerothcore
