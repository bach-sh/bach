#!/usr/bin/env bash
set -euo pipefail
curr_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P)"
source "${curr_dir}"/../bach.sh

test-this-is-a-normal-test-case() {
    @true Does not have an assertion function
}
test-this-is-a-normal-test-case-assert() {
    @do-nothing
}
