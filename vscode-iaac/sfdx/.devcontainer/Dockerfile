# [Choice] Python version: 3, 3.9, 3.8, 3.7, 3.6
ARG VARIANT=3
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT} as base-builder

# Copy library scripts to execute
COPY .devcontainer/library-scripts/wrap_chrome_binary /opt/bin/wrap_chrome_binary
COPY .devcontainer/library-scripts/*.sh /tmp/library-scripts/
COPY .devcontainer/packages/*.*         /tmp/packages-tmp/
COPY .devcontainer/tests                /tests

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="true"
# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN set -ex \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common nano \
    # Install common packages, non-root user
    && bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Use Docker script from script library to set things up
    && /bin/bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}" "${USE_MOBY}" \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to
# the Docker socket if "overrideCommand": false is set in devcontainer.json.
# The script will also execute CMD if you need to alter startup behaviors.
ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Google Chrome
ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Chrome Launch Script Wrapper
RUN  /opt/bin/wrap_chrome_binary

# Chrome webdriver
ARG CHROME_DRIVER_VERSION
RUN if [ -z "$CHROME_DRIVER_VERSION" ]; \
  then CHROME_MAJOR_VERSION=$(google-chrome --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/") \
    && CHROME_DRIVER_VERSION=$(wget --no-verbose -O - "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_MAJOR_VERSION}"); \
  fi \
  && echo "Using chromedriver version: "$CHROME_DRIVER_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \
  && rm -rf /opt/selenium/chromedriver \
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && sudo ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

RUN echo "chrome" > /opt/selenium/browser_name
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

# shellspec, kcov, gh, geckodriver
FROM shellspec/shellspec-debian:kcov as shellspec-kov-gh

ENV GH_VER=1.12.1
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

# Install Node.js
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
    && CMD="npm install -g npm commitizen commitlint release-it sfdx-cli" \
    && su vscode -c "source /usr/local/share/nvm/nvm.sh && $CMD" 2>&1
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

# Python packages
FROM node-builder as python-builder
RUN set -ex \
    && pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/packages-tmp/requirements.txt

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

# OS packages + goss validator
FROM python-builder as dev-container

RUN set -ex \
    && apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && bash /tmp/library-scripts/install_os_dependencies.sh "install" \
    && apt-get autoremove -y  \
    && apt-get clean -y \
    && rm -r /var/cache/* /var/lib/apt/lists/*

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

COPY .devcontainer/dotfiles/.zshrc /home/$USERNAME/

# Remove library scripts for final image
RUN set -ex \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/*  \
    && rm -rf /tmp/library-scripts \
    && rm -rf /tmp/packages-tmp
