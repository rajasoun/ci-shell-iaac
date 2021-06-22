#!/usr/bin/env bash

su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install --no-progress -g npm commitizen commitlint release-it sfdx-cli" 2>&1