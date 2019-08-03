#!/usr/bin/env bash
declare -grx self="$(realpath "${BASH_SOURCE}")"
source <("${self%/*/*}"/cflib-import.sh)
require bach

#declare -a BACH_ASSERT_DIFF_OPTS=(-w -y)
export BACH_DEBUG=true

test-rm-rf() {
    project_log_path=/tmp/project/logs
    sudo rm -rf "$project_log_ptah/" # Typo here!
}
test-rm-rf-assert() {
    sudo rm -rf /   # This is the actual command to run on your host!
                    # DO NOT PANIC! By using Bach Testing Framework it won't actually run.
}

test-rm-your-dot-git() {
    # Mock `find` command with certain parameters, will output two directories

    @mock find ~ -type d -name .git === @stdout ~/src/your-awesome-project/.git \
                                                ~/src/code/.git

    # Do it, remove all .git directories
    find ~ -type d -name .git | xargs -- rm -rf
}
test-rm-your-dot-git-assert() {
    # Verify the actual command

    rm -rf ~/src/your-awesome-project/.git ~/src/code/.git
}

test-output() {
    @out out1
    @echo out2 | @out
    @out "out3 " <<EOF
one
two
three
EOF
}
test-output-assert() {
    @cat <<EOF
out1
out2
out3 one
out3 two
out3 three
EOF
}

test-run() {
    @mock load-script === @echo "'for param; do \"${_echo}\" \"script.sh - \$param\"; done'"

    @run <(load-script) foo bar
}
test-run-assert() {
    @cat <<EOF
script.sh - foo
script.sh - bar
EOF
}

test-run-no-filename() {
    @run
}
test-run-no-filename-assert() {
    @false
}

testmd5sum() {
    @mock command which md5sum === fake-md5sum
    @real md5sum --version
    @real diff --version
}
testmd5sum-assert() {
    fake-md5sum --version
    @diff --version
}

this_variable_exists=""
this_variable_exists_in_test=""
this_variable_exists_in_assert=""
@setup {
    declare -g this_variable_exists=in_test_and_assert
    declare -g this_variable_exists_in_test=""
    declare -g this_variable_exists_in_assert=""
}

@setup-test {
    @ignore echo

    @mock git config --get branch.master.remote === @stdout "remote-master"
    @mock git rev-parse --abbrev-ref HEAD <<-MOCK
			@stdout branch-name
		MOCK

    declare -g this_variable_exists_in_test=in_test
}

@setup-assert {
    declare -g this_variable_exists_in_assert=in_assert
}

test-bach-setup() {
    if [[ -n "$this_variable_exists" ]]; then @echo "$this_variable_exists"; else @echo TEST setup fail; fi
    if [[ -n "$this_variable_exists_in_test" ]]; then @echo setup-test; else @echo TEST setup setup-test fail; fi
    if [[ -z "$this_variable_exists_in_assert" ]]; then @echo setup-assert; else @echo TEST should NOT setup setup-assert; fi
}
test-bach-setup-assert() {
    if [[ -n "$this_variable_exists" ]]; then @echo "$this_variable_exists"; else @echo ASSERT setup fail; fi
    if [[ -z "$this_variable_exists_in_test" ]]; then @echo setup-test; else @echo ASSERT should NOT setup setup-assert; fi
    if [[ -n "$this_variable_exists_in_assert" ]]; then @echo setup-assert; else @echo ASSERT setup pre-assert fail; fi
}

test1() {
    @mock find . -name fn === @stdout file1 file2

    ls $(find . -name fn)

    @mock ls file1 file2 === file2 file1
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

    @err no error 2>/dev/null
    @err error 2>&1 1>/dev/null

    @mockfalse ls /bin
    ls /bin &>/dev/null || @stdout "ls /foo: No such file or directory"
}
test2-assert() {
    cd /src
    sudo rm -rf /src/project

    @echo error
    @echo "ls /foo: No such file or directory"
}

function load-gp() {
    @load_function "${self%/*}/example-functions" gp
}

test-gp-1() {
    load-gp

    @mocktrue git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    gp
    gp another-remote
    gp another-remote another-branch
    gp -f
}
test-gp-1-assert() {
    git push remote-master branch-name
    git push another-remote branch-name
    git push another-remote another-branch
    git push -f remote-master branch-name
}

test-gp-2() {
    load-gp

    @mockfalse git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    gp
    gp another-remote
    gp another-remote another-branch
    gp -f
}
test-gp-2-assert() {
    git push -u remote-master branch-name
    git push -u another-remote branch-name
    git push -u another-remote another-branch
    git push -f -u remote-master branch-name
}

function init-current-working-dir-is-not-a-repo() {
    @mockfalse git config --get branch.master.remote
    @mockfalse git rev-parse --abbrev-ref HEAD
    @mockfalse git rev-parse --abbrev-ref --symbolic-full-name '@{u}'

}

test-gp-not-a-repo() {
    load-gp
    init-current-working-dir-is-not-a-repo

    set -eu
    gp
}
test-gp-not-a-repo-assert() {
    @false
}


test-gp-not-a-repo1() {
    load-gp
    init-current-working-dir-is-not-a-repo

    set -eu
    gp origin
}
test-gp-not-a-repo1-assert() {
    false
}

test-bach-real-command-mock-builtin() {
    @mock command which grep === @stdout fake-grep
    bach-real-command grep --version
    command id
}
test-bach-real-command-mock-builtin-assert() {
    fake-grep --version
    id
}

test-bach-real-command-slash-bin() {
    bach-real-command hostname -f
}
test-bach-real-command-slash-bin-assert() {
    /bin/hostname -f
}

test-bach-simple-command() {
    hostname -f
}
test-bach-simple-command-assert() {
    hostname -f
}

test-must-have-an-assertion() {
    test-must-have-an-assertion-assert
}

test-SKIP-must-have-an-assertion-assert() {
    :
}

function load-ff() {
    @load_function "${self%/*}/example-functions" ff
}

test-ff-1() {
    load-ff

    ff
    ff file1
}
test-ff-1-assert() {
    find . -type f -name "*"
    find . -type f -name "*file1*"
}

test-ff-2() {
    load-ff

    ff file1 bar
}
test-ff-2-assert() {
    find . -type f -name "*file1*" -or -name "*bar*"
}

test-mock-absolute-path-of-script() {
    @mock /tmp/cannot-mock-this 2>&1
}
test-mock-absolute-path-of-script-assert() {
    #printf "\e[1;31m%s\e[0;m\n"
    @echo 'Cannot mock an absolute path: /tmp/cannot-mock-this'
    return 1
}

test-mock-script() {
    @mock ./path/to/script
    ./path/to/script foo bar
}
test-mock-script-assert() {
    @echo ./path/to/script foo bar
}

test-mock-existed-script() {
    @mock ./cannot-mock-existed-script 2>&1 || return 1
    @mock ./cannot-mock-existed-script 2>&1
    @assert-fail Should not go here
    ./cannot-mock-existed-script foo bar    2>&1
}
test-mock-existed-script-assert() {
    @echo 'Cannot mock an existed path: ./cannot-mock-existed-script'
    return 1
}

test-mock-script-1() {
    @mock ./path/to/script === something
    ./path/to/script
}
test-mock-script-1-assert() {
    something
}

test-mock-script-2() {
    @mock ./path/to/script <<\SCRIPT
if [[ "$1" == foo ]]; then
  @echo bar
else
  @echo anything
fi
SCRIPT
    ./path/to/script foo
    ./path/to/script something
}
test-mock-script-2-assert() {
    bar
    anything
}

test-bach-run-tests--get-all-tests() {
    @mock @shuf === @cat
    @mock bach-get-all-functions <<EOF
@echo declare -f gp
@echo declare -f test-bach-run-tests--get-all-tests-foo
@echo declare -f test-bach-run-tests--get-all-tests-bar
@echo declare -f test-bach-run-tests--get-all-tests-bar1
@echo declare -f test-bach-run-tests--get-all-tests-bar2
@echo declare -f test-bach-run-tests--get-all-tests-bar-assert
EOF

    bach-run-tests--get-all-tests
}
test-bach-run-tests--get-all-tests-assert() {
    test-bach-run-tests--get-all-tests-foo
    test-bach-run-tests--get-all-tests-bar
    test-bach-run-tests--get-all-tests-bar1
    test-bach-run-tests--get-all-tests-bar2
}


test-forbidden-running-@mock() {
    @echo @mock anything === anything
    @echo @ignore foobar
}
test-forbidden-running-@mock-assert() {
    @type -t @mock 2>&1
    @mock anything === anything
    @ignore foobar
}

test-mock-cd() {
    exec 2>&1
    cd /path
}
test-mock-cd-assert() {
    exec 2>&1
    @echo cd /path
}

test-mock-echo() {
    unset -f echo
    @mock echo
    @type -t echo
    echo done
}
test-mock-echo-assert() {
    @echo function
    @echo echo done
}
