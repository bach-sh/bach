#!/usr/bin/env bash
set -euo pipefail

export CFLIB_INC_PATH="$HOME/src/common-functions-lib"; source "$CFLIB_INC_PATH/cflib-import.sh"
require colorize

#export BESTING_DEBUG=true
require mockframework

@setup {
    ignore-command echo

    @mock git config --get branch.master.remote -- stdout "remote-master"
    @mock git rev-parse --abbrev-ref HEAD <<-MOCK
			stdout branch-name
		MOCK
}

test1() {
    @mock find . -name fn -- file1 file2

    ls $(find . -name fn)

    @mock ls file1 file2 -- file2 file1
    ls $(find . -name fn) | xargs -n1 -- do-something


    project_path=/src/project
    cd "${project_path%/*}"
    sudo rm -rf $project_path


    @mock git rev-parse --abbrev-ref --symbolic-full-name '@{u}' -- return 1
    gp

    err error 2>&1
    /bin/ls /foo 2>&1
}
test1-assert() {
    ls file1 file2

    do-something file2
    do-something file1

    cd /src
    sudo rm -rf /src/project

    git push -u remote-master branch-name
    printf "\e[1;31merror\e[0;m\n"
    out "ls: /foo: No such file or directory"
}

load_function ~/.profile.d/90-aliases.sh gp

test-gp-1() {
    @mock git rev-parse --abbrev-ref --symbolic-full-name '@{u}' -- return 0

    gp
}
test-gp-1-assert() {
    git push remote-master branch-name
}


test-besting-real-command-mock-builtin() {
    @mock command which grep -- stdout fake-grep
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
