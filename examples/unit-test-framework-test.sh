#!/usr/bin/env bash
set -euo pipefail
declare -grx self="$(realpath "${BASH_SOURCE}")"
source <("${self%/*/*}"/cflib-import.sh)
require colorize
require mockframework

#declare -a BESTING_ASSERT_DIFF_OPTS=(-w -y)
export BESTING_DEBUG=true
testmd5sum() {
    @mock command which md5sum -- fake-md5sum
    @real md5sum --version
    @real diff --version
}
testmd5sum-assert() {
    fake-md5sum --version
    _diff --version
}

@setup {
    @ignore echo

    @mock git config --get branch.master.remote -- @stdout "remote-master"
    @mock git rev-parse --abbrev-ref HEAD <<-MOCK
			@stdout branch-name
		MOCK
}

test1() {
    @mock find . -name fn -- @stdout file1 file2

    ls $(find . -name fn)

    @mock ls file1 file2 -- file2 file1
    ls $(find . -name fn) | xargs -n1 -- do-something
}
test1-assert() {
    ls file1 file2

    do-something file2
    do-something file1
}

test2() {
    project_path=/src/project
    cd "${project_path%/*}"
    sudo rm -rf $project_path

    err error 2>&1
    /bin/ls /foo &>/dev/null || @stdout "ls /foo: No such file or directory"
}
test2-assert() {
    cd /src
    sudo rm -rf /src/project

    printf "\e[1;31merror\e[0;m\n"
    echo "ls /foo: No such file or directory"
}

function load-gp() {
    @load_function "${self%/*}/example-functions" gp
}

test-gp-1() {
    load-gp

    @mocktrue git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    gp
}
test-gp-1-assert() {
    git push remote-master branch-name
}

test-gp-2() {
    load-gp

    @mockfalse git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    gp
}
test-gp-2-assert() {
    git push -u remote-master branch-name
}

test-besting-real-command-mock-builtin() {
    @mock command which grep -- @stdout fake-grep
    besting-real-command grep --version
    command id
}
test-besting-real-command-mock-builtin-assert() {
    fake-grep --version
    id
}

test-besting-real-command-slash-bin() {
    besting-real-command hostname -f
}
test-besting-real-command-slash-bin-assert() {
    /bin/hostname -f
}

test-besting-simple-command() {
    hostname -f
}
test-besting-simple-command-assert() {
    hostname -f
}

test-must-have-an-assertion() {
    test-must-have-an-assertion-assert
}
