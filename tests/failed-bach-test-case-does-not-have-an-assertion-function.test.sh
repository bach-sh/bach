#!/usr/bin/env bash
set -euo pipefail
curr_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P)"
source "${curr_dir}"/../bach.sh

test-this-test-case-does-not-have-an-assertion-function() {
    @echo This test case MUST FAIL!
    @echo This is what WE EXPECTED.
    @echo This test case DOES NOT have an assertion function
    @echo Please ignore this failed message.
}
