#!/usr/bin/env bash
set -euo pipefail
curr_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P)"
source "${curr_dir}"/../bach.sh

test-ASSERT-FAIL-exit-1-should-success() {
    @echo This test case SHOULD SUCCESS!
    @echo Because the exit code is non-zero.
    do-something
    exit 1
}
