# Continous Intgeration Shell 

Generic Continous Intgeration Shell helps in building docker Containers of Visual Studio Code and verify its correctness

## Launching the CI Shell Container

```
docker run --rm -it \
    --name ci-shell \
    --hostname ci-shell \
    -v "$(pwd):$(pwd)" \
    -v /var/run/docker.sock:/var/run/docker.sock  \
    -w "$(pwd)"  \
    rajasoun/ci-shell:latest
```

## Getting Started 

Inside the CI Shell

```
cd /workspaces/
git clone https://github.com/rajasoun/ci-shell-iaac && cd ci-shell-iaac
goss --gossfile ci-shell/iaac/gossfile.goss.yaml validate --format tap  # for IaaC Test
./ci.sh        # in getting available options
```
