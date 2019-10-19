#!/usr/bin/env bash
curr_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P)"
source "${curr_dir}"/../bach.sh

function release-sh() {
    @run "$curr_dir/../release.sh" "$@"
}

@setup-test {
    @ignore echo
    @mocktrue sed -Ene '/^## Versioning$/,+2p' README.md
}


test-ASSERT-FAIL-without-parameters() {
    release-sh
}


test-pass-a-valid-tag() {
    @mock git tag --list 1.2.3 === @stdout 1.2.3
    @mocktrue grep -F 1.2.3
    release-sh 1.2.3
}
test-pass-a-valid-tag-assert() {
    git push
    git push --tags
    hub release create -m "v1.2.3

Version 1.2.3" 1.2.3
}


test-pass-a-valid-tag-but-readme-not-updated() {
    @mock git tag --list 1.2.4 === @stdout 1.2.4
    @mockfalse grep -F 1.2.4
    release-sh 1.2.4
}
test-pass-a-valid-tag-but-readme-not-updated-assert() {
    @false
}


test-pass-a-non-existed-tag() {
    @mocktrue git tag --list 42.0
    release-sh 42.0
}
test-pass-a-non-existed-tag-assert() {
    @false
}
