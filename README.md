# Continous Intgeration Shell 

Generic Continous Intgeration Shell helps in building docker Containers of Visual Studio Code and verify its correctness

## Launching the CI Shell Container

docker run --rm -it \
    --name ci-shell \
    --hostname ci-shell \
    -v "$(pwd):$(pwd)" \
    -v /var/run/docker.sock:/var/run/docker.sock  \
    -w "$(pwd)"  \
    rajasoun/ci-shell:latest

## Getting Started 

Open Terminal 

1. Run `./ci.sh` in getting available options
1. Run `./ci.sh build` to build the ci-shell container
1. Run `./ci.sh shell` to launch the ci-shell
1. Run `goss --gossfile ci-shell/iaac/gossfile.goss.yaml validate --format tap` for IaaC Test