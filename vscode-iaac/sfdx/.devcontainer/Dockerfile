# Note: You can use any Debian/Ubuntu based image you want.
FROM mcr.microsoft.com/vscode/devcontainers/base:0-buster AS dind-builder

ENV LANG C.UTF-8

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"
# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="true"
# [Option] Use the OSS Moby CLI instead of the licensed Docker CLI
ARG USE_MOBY="true"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your
# own dependencies. A user of "automatic" attempts to reuse an user ID if one already exists.
ARG USERNAME=automatic
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Use Docker script from script library to set things up
    && /bin/bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}" "${USE_MOBY}" \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to
# the Docker socket if "overrideCommand": false is set in devcontainer.json.
# The script will also execute CMD if you need to alter startup behaviors.
ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]

# OS packages.
RUN set -ex \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends dpkg-dev gcc g++ make \
        tzdata libreadline-dev libffi-dev shellcheck python3-dev python3-pip \
        binutils libcurl4 zlib1g libdw1 zlib1g-dev  \
        vim netcat jq git-flow firefox-esr \
    && apt-get autoremove -y  \
    && apt-get clean -y \
    && rm -r /var/cache/* /var/lib/apt/lists/*

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Node packages
FROM node:16.3.0-buster-slim as node-packages
RUN set -ex \
    && npm install -g npm commitizen commitlint release-it sfdx-cli  2>&1

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

# shellspec, kcov, gh, geckodriver
FROM shellspec/shellspec-debian:kcov as shellspec-kov-gh

ENV GH_VER=1.11.0
ENV GH_CLI=https://github.com/cli/cli/releases/download/v${GH_VER}/gh_${GH_VER}_linux_amd64.tar.gz
ENV GECKO_DRIVER=https://github.com/mozilla/geckodriver/releases/download/v0.29.1/geckodriver-v0.29.1-linux64.tar.gz
RUN set -ex \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends  wget tar \
    && wget -q $GH_CLI -O - | tar xz -C ./ --strip-components 1 \
    && wget -q $GECKO_DRIVER -O - | tar xz -C /usr/local/bin \
    && apt-get autoremove -y  \
    && apt-get clean -y \
    && rm -r /var/cache/* /var/lib/apt/lists/*

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

# Python 3 Packages
FROM python:3.7-slim-buster as python-packages
RUN set -ex \
    && pip3 --disable-pip-version-check --no-cache-dir install \
        pipx==0.16.3        \
        ggshield==1.4.0     \
        pre-commit==2.12.1  \
        commitizen==2.17.3  \
        cruft==2.8.0        \
        cumulusci==3.35.0   \
    && rm -rf /tmp/pip-tmp

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# dev-container
FROM dind-builder

# shellspec
COPY --from=shellspec-kov-gh   /opt/shellspec                         /opt/shellspec
# kcov
COPY --from=shellspec-kov-gh   /usr/local/bin/kcov*                   /usr/local/bin/
COPY --from=shellspec-kov-gh   /usr/local/share                       /usr/local/share/doc/kcov
# gh and geckodriver
COPY --from=shellspec-kov-gh   /src                                    /usr/local
COPY --from=shellspec-kov-gh   /usr/local/bin/geckodriver              /usr/local/bin

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# node packages
COPY --from=node-packages       /usr/local/                /usr/local/
# Install Node.js
ENV NVM_DIR="/usr/local/nvm"
ENV NODE_VERSION=v16.3.0
RUN set -ex \
    && mkdir -p $NVM_DIR \
    && curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION

ENV NODE_PATH="$NVM_DIR/v$NODE_VERSION/lib/node_modules"
ENV PATH="$NVM_DIR/v$NODE_VERSION/bin:$PATH"

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# python packages
COPY --from=python-packages    /usr/local                   /usr/local

# ENV PATH="/opt/shellspec:/chromedriver:$PATH"
ENV PATH="/opt/shellspec:$PATH"

RUN set -x \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/ /chromedriver/chromedriver_*.zip
