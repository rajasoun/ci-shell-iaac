# [Choice] Python version: 3, 3.9, 3.8, 3.7, 3.6
ARG VARIANT=3.9
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT} as base-builder

# Copy library scripts to execute
COPY .devcontainer/library-scripts/*.sh /tmp/library-scripts/
COPY .devcontainer/packages/*.*         /tmp/packages-tmp/
COPY .devcontainer/tests                /tests

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# os packages and docker
RUN set -ex \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common nano \
    # Install os packages
    && bash /tmp/library-scripts/os-dependencies.sh "install" \
    # Use Docker script from script library to set things up
    && /bin/bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}" "${USE_MOBY}" \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

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
# Node.js
FROM base-builder as node-builder
ARG INSTALL_NODE="true"
ARG NODE_VERSION="none"
ENV NVM_DIR=/usr/local/share/nvm
ENV NVM_SYMLINK_CURRENT=true \
    PATH=${NVM_DIR}/current/bin:${PATH}
RUN set -ex \
    && if [ "$INSTALL_NODE" = "true" ]; then bash /tmp/library-scripts/node-debian.sh "${NVM_DIR}" "${NODE_VERSION}" "${USERNAME}"; fi \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Global node packages.
RUN set -ex \
    && su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install --no-progress -g npm commitizen commitlint release-it sfdx-cli" 2>&1

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Python packages
FROM node-builder as python-builder
RUN set -ex \
    && pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/packages-tmp/requirements.txt

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# goss validator
FROM python-builder as dev-container
RUN set -ex \
    && curl -fsSL https://goss.rocks/install | sh

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

# Dev Container
FROM dev-container
# shellspec
COPY --from=shellspec-kov-gh   /opt/shellspec                         /opt/shellspec
# kcov
COPY --from=shellspec-kov-gh   /usr/local/bin/kcov*                   /usr/local/bin/
COPY --from=shellspec-kov-gh   /usr/local/share                       /usr/local/share/doc/kcov
# gh
COPY --from=shellspec-kov-gh   /src                                    /usr/local
# geckodriver
COPY --from=shellspec-kov-gh   /usr/local/bin/geckodriver              /usr/local/bin

ENV PATH="/opt/shellspec:$PATH"

# Remove library scripts for final image
RUN set -ex \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/*  \
    && rm -rf /tmp/library-scripts \
    && rm -rf /tmp/packages-tmp

# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to
# the Docker socket if "overrideCommand": false is set in devcontainer.json.
# The script will also execute CMD if you need to alter startup behaviors.
ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]
