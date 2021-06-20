#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/src/load.sh"

VERBOSE=0
DEBUG_TOGGLE="${3:-}"  # If -d is present - debug is on - else off

DEFAULT_SHELL="go"
SHELL_TYPE="${1:-$DEFAULT_SHELL}" # If shell type not set or null, use default.
export VERBOSE SHELL_TYPE

_debug_option "$DEBUG_TOGGLE"
check jq
_file_exist "$CONFIG_DIR/$CONFIG_FILE" 

opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case ${choice} in
    "e2e")
        export DOCKER_BUILDKIT=1
        build_container > /dev/null 2>&1
        e2e_tests
        tear_down
    ;;
    "build")
        build_container
    ;;
    "shell")
        _populate_dev_container_env
        export DOCKER_BUILDKIT=1
        build_container
        shell_2_container
    ;;
    "teardown")
        tear_down
    ;;
    *)
    echo "${RED}Usage: automator/ci.sh <e2e | taerdown | shell> [-d]${NC}"
cat <<-EOF
Commands:
---------
  build       -> Build Container
  shell       -> Shell into the Dev Container
  teardown    -> Teardown Dev Container
  e2e         -> Build Dev Container,Run End to End IaaC Test Scripts and Teardown
EOF
    ;;
esac
