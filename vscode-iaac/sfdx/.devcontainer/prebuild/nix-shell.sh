#!/usr/bin/env bash

docker run --rm -it --name nix-shell \
        --sig-proxy=false \
        -a STDOUT -a STDERR \
        --entrypoint=/bin/zsh \
        --user vscode  \
        --mount type=bind,source="${PWD}",target=/workspaces/application-profiler,consistency=cached \
        --mount source=/var/run/docker.sock,target=/var/run/docker-host.sock,type=bind \
        --mount type=volume,src=vscode,dst=/vscode -l vsch.local.folder="${PWD}" \
        -l vsch.quality=stable -l vsch.remote.devPort=0 \
        -w "/workspaces/application-profiler" \
        --init rajasoun/devcontainer:0.1.1
