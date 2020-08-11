#!/usr/bin/env bash
curr_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P)"
source "${curr_dir}"/../bach.sh

@setup-test {
    # @mock echo 726d202d7266202a === @echo 726d202d7266202a
    ## or
    @unmock echo
}

test-xxd() {
    $(echo 726d202d7266202a | xxd -r -p)
}
test-xxd-assert() {
    xxd -r -p
}

test-mock-xxd() {
    @mock xxd -r -p === rm -rf *

    $(echo 726d202d7266202a | xxd -r -p)
}
test-mock-xxd-assert() {
    rm -rf *
}

test-real-xxd() {
    @mock xxd -r -p === @real xxd -r -p

    $(echo 726d202d7266202a | xxd -r -p)
}
test-real-xxd-assert() {
    rm -rf *
}
