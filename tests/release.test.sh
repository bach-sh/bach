#!/usr/bin/env bash
curr_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P)"
source "${curr_dir}"/../bach.sh

function release-sh() {
    @run "$curr_dir/../release.sh" "$@"
}

@setup-test {
    @ignore echo
    @mocktrue sed -Ene '/^## Versioning$/,+2p' README.md
    @mockfalse hash mmark
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
    git push --follow-tags
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

test-convert-to-html() {
    @mock find . -maxdepth 1 -type f -name "README*.md" === @stdout ./README-zh_CN.md ./README.md

    @mocktrue hash mmark
    @mock grep '<h1 ' index.html === @stdout "Bach Unit Testing Framework for Bash"
    @mock grep '<h1 ' index-zh_CN.html === @stdout "Bash 脚本的 Bach 单元测试框架"
    @mockpipe sed "s/<[^>]\+>//g"
    @mock tee index-zh_CN.html
    @mock tee index.html

    test-pass-a-valid-tag
}
test-convert-to-html-assert() {
    test-pass-a-valid-tag-assert

    mmark -html -css //bach.sh/solarized-dark.min.css README-zh_CN.md
    sed -i "/<title>/s/>/>Bash 脚本的 Bach 单元测试框架/" index-zh_CN.html

    mmark -html -css //bach.sh/solarized-dark.min.css README.md
    sed -i "/<title>/s/>/>Bach Unit Testing Framework for Bash/" index.html
}
