#!/usr/bin/env bash
declare -grx self="$(realpath "${BASH_SOURCE}")"
source <("${self%/*/*}"/cflib-import.sh)
require bach

# export BACH_DISABLED=false
# export BACH_COLOR=auto
# export BACH_DEBUG=true
# export BACH_ASSERT_DIFF=diff
# export BACH_ASSERT_IGNORE_COMMENT=true
# declare -a BACH_ASSERT_DIFF_OPTS=(-u)

test-rm--rf() {
    @do-not-panic
    project_log_path=/tmp/project/logs
    sudo rm -rf "$project_log_ptah/" # Typo here!
}
test-rm--rf-assert() {
    @do-not-panic
    sudo rm -rf /   # This is the actual command to run on your host!
                    # DO NOT PANIC! By using Bach Testing Framework it won't actually run.
}

test-rm-your-dot-git() {
    @do-not-panic
    # Mock `find` command with certain parameters, will output two directories
    @mock find ~ -type d -name .git === @stdout ~/src/your-awesome-project/.git \
                                                ~/src/code/.git
    # Do it, remove all .git directories
    find ~ -type d -name .git | xargs -- rm -rf
}
test-rm-your-dot-git-assert() {
    @do-not-panic
    # Verify the actual command
    rm -rf ~/src/your-awesome-project/.git ~/src/code/.git
}

test-learn-bash:-no-double-quote() {
    function foo() {
        no-double-quote $@
    }
    # We passed ONE parameter to this function
    foo "a b c d"
}
test-learn-bash:-no-double-quote-assert() {
    # But the command 'no-double-quote' received FOUR parameters!
    no-double-quote a b c d
}

test-learn-bash:-double-quotes() {
    function foo() {
        double-quotes "$@"
    }
    # We passed ONE parameter to this function
    foo "a b c d"
}
test-learn-bash:-double-quotes-assert() {
    # Yes, the command 'double-quotes' received the correct parameter
    double-quotes "a b c d"
}

test-learn-bash:-no-double-quote-star() {
    @touch bar1 bar2 bar3 "bar*"

    function cleanup() {
        rm -rf $1
    }

    # We want to remove the file "bar*", not the others
    cleanup "bar*"
}
test-learn-bash:-no-double-quote-star-assert() {
    # Without double quotes, all bar files are removed!
    rm -rf "bar*" bar1 bar2 bar3
}

test-learn-bash:-double-quote-star() {
    @touch bar1 bar2 bar3 "bar*"

    function cleanup() {
        rm -rf "$1"
    }

    # We want to remove the file "bar*", not the others
    cleanup "bar*"
}
test-learn-bash:-double-quote-star-assert() {
    # Yes, with double quotes, only the file "bar*" is removed
    rm -rf "bar*"
}

test-output-function-@out() {
    @out out1
    @echo out2 | @out
    @out "out3 " <<EOF
one
two
three
EOF
}
test-output-function-@out-assert() {
    @cat <<EOF
out1
out2
out3 one
out3 two
out3 three
EOF
}


test-output-function-@out-stdin() {
    set -euo pipefail
    @out - <<EOF
one
two
three
EOF
}
test-output-function-@out-stdin-assert() {
    @cat <<EOF
one
two
three
EOF
}


test-run-a-script() {
    @mock load-script === @echo "'for param; do \"${_echo}\" \"script.sh - \$param\"; done'"

    @run <(load-script) foo bar
}
test-run-a-script-assert() {
    @cat <<EOF
script.sh - foo
script.sh - bar
EOF
}

test-run-with-no-filename() {
    @run
}
test-run-with-no-filename-assert() {
    @fail
}

test-mock-command-which-something() {
    @mock command which something === fake-something
    command which something
}
test-mock-command-which-something-assert() {
    fake-something
}


test-mock-builtin-command-with-external-commands1() {
    @mock command mycmd param1 === @stdout myoutput

    @type -t command

    mycmd param1 | @grep -F myoutput
}
test-mock-builtin-command-with-external-commands1-assert() {
    @echo function
    @echo myoutput
}


test-mock-builtin-command-with-external-commands2() {
    @mock command mycmd param1 === @stdout myoutput

    @type -t command

    command mycmd param1 | @grep -F myoutput
}
test-mock-builtin-command-with-external-commands2-assert() {
    @echo function
    @echo myoutput
}


test-@real-function() {
    unset -f bach-real-path
    @mock bach-real-path md5sum === fake-md5sum

    @real md5sum
    @real md5sum --version
}
test-@real-function-assert() {
    fake-md5sum
    fake-md5sum --version
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

test-bach-framework-setup-functions() {
    if [[ -n "$this_variable_exists" ]]; then @echo "$this_variable_exists"; else @echo TEST setup fail; fi
    if [[ -n "$this_variable_exists_in_test" ]]; then @echo setup-test; else @echo TEST setup setup-test fail; fi
    if [[ -z "$this_variable_exists_in_assert" ]]; then @echo setup-assert; else @echo TEST should NOT setup setup-assert; fi
}
test-bach-framework-setup-functions-assert() {
    if [[ -n "$this_variable_exists" ]]; then @echo "$this_variable_exists"; else @echo ASSERT setup fail; fi
    if [[ -z "$this_variable_exists_in_test" ]]; then @echo setup-test; else @echo ASSERT should NOT setup setup-assert; fi
    if [[ -n "$this_variable_exists_in_assert" ]]; then @echo setup-assert; else @echo ASSERT setup pre-assert fail; fi
}

test-bach-framework-mock-commands() {
    @mock find . -name fn === @stdout file1 file2

    ls $(find . -name fn)

    @mock ls file1 file2 === @stdout file2 file1
    ls $(find . -name fn) | xargs -n1 -- do-something
}
test-bach-framework-mock-commands-assert() {
    ls file1 file2

    do-something file2
    do-something file1
}

test-bach-framework-error-output() {
    project_path=/src/project
    cd "${project_path%/*}"
    sudo rm -rf $project_path

    @err no error 2>/dev/null
    @err error 2>&1 1>/dev/null

    @mockfalse ls /bin
    ls /bin &>/dev/null || @stdout "ls /foo: No such file or directory"
}
test-bach-framework-error-output-assert() {
    cd /src
    sudo rm -rf /src/project

    @echo error
    @echo "ls /foo: No such file or directory"
}

function load-gp() {
    @load_function "${self%/*}/example-functions" gp
}

test-gp-running-inside-a-git-repo-and-the-branch-has-upstream() {
    load-gp

    @mocktrue git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    gp
    gp another-remote
    gp another-remote another-branch
    gp -f
}
test-gp-running-inside-a-git-repo-and-the-branch-has-upstream-assert() {
    git push remote-master branch-name
    git push another-remote branch-name
    git push another-remote another-branch
    git push -f remote-master branch-name
}

test-gp-running-inside-a-git-repo-and-the-branch-does-not-have-upstream() {
    load-gp

    @mockfalse git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    gp
    gp another-remote
    gp another-remote another-branch
    gp -f
}
test-gp-running-inside-a-git-repo-and-the-branch-does-not-have-upstream-assert() {
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

test-gp-running-not-inside-a-valid-git-repo() {
    load-gp
    init-current-working-dir-is-not-a-repo

    set -eu
    gp
}
test-gp-running-not-inside-a-valid-git-repo-assert() {
    @fail
}


test-gp-running-not-inside-a-valid-git-repo-again() {
    load-gp
    init-current-working-dir-is-not-a-repo

    set -eu
    gp origin
}
test-gp-running-not-inside-a-valid-git-repo-again-assert() {
    @fail
}


test-bach-real-command-mock-builtin() {
    command hostname
    command id -u
}
test-bach-real-command-mock-builtin-assert() {
    @dryrun hostname
    @dryrun id -u
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
    : do nothing
}

test-must-have-an-assertion-assert() {
    : do nothing
}

function load-ff() {
    @load_function "${self%/*}/example-functions" ff
}

test-load-and-test-ff-function() {
    load-ff

    ff
    ff file1
}
test-load-and-test-ff-function-assert() {
    find . -type f -name "*"
    find . -type f -name "*file1*"
}

test-load-and-test-ff-function-with-multi-filenames() {
    load-ff

    ff file1 bar "file name"
}
test-load-and-test-ff-function-with-multi-filenames-assert() {
    find . -type f -name "*file1*" -or -name "*bar*" -or -name "*file name*"
}

test-cannot-mock-absolute-path-of-script() {
    @mock /tmp/cannot-mock-this 2>&1
}
test-cannot-mock-absolute-path-of-script-assert() {
    #printf "\e[1;31m%s\e[0;m\n"
    @echo 'Cannot mock an absolute path: /tmp/cannot-mock-this'
    @fail
}

test-mock-script() {
    @mock ./path/to/script
    ./path/to/script foo bar
}
test-mock-script-assert() {
    @dryrun ./path/to/script foo bar
}

test-cannot-mock-existed-script() {
    @mock ./cannot-mock-existed-script 2>&1 || return 1
    @mock ./cannot-mock-existed-script 2>&1
    @fail 2 It should not go here
    ./cannot-mock-existed-script foo bar    2>&1
}
test-cannot-mock-existed-script-assert() {
    @echo 'Cannot mock an existed path: ./cannot-mock-existed-script'
    @fail
}

test-mock-script-with-custom-action() {
    @mock ./path/to/script === something
    ./path/to/script
}
test-mock-script-with-custom-action-assert() {
    something
}

test-mock-script-with-custom-complex-action() {
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
test-mock-script-with-custom-complex-action-assert() {
    bar
    anything
}

test-bach-framework-can-get-all-tests() {
    unset -f bach-get-all-functions @shuf
    @mock @shuf === @sort
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
test-bach-framework-can-get-all-tests-assert() {
    test-bach-run-tests--get-all-tests-bar
    test-bach-run-tests--get-all-tests-bar1
    test-bach-run-tests--get-all-tests-bar2
    test-bach-run-tests--get-all-tests-foo
}

test-dryrun-should-split-parameters-by-two-spaces() {
    no-parameter
    @dryrun one-parameter '{ "foo": 1, "bar": 2 }'
    multi-parameters "{ 'foo': 1, 'bar': 2 }" '{ "foo": 1, "bar": 2 }'
}
test-dryrun-should-split-parameters-by-two-spaces-assert() {
    @cat <<EOF
no-parameter
one-parameter  { "foo": 1, "bar": 2 }
multi-parameters  { 'foo': 1, 'bar': 2 }  { "foo": 1, "bar": 2 }
EOF
}

test-forbidden-running-mock-inside-assertion() {
    @dryrun @mock anything === anything
    @dryrun @ignore foobar
}
test-forbidden-running-mock-inside-assertion-assert() {
    @type -t @mock 2>&1
    @mock anything === anything
    @ignore foobar
}

test-mock-cd-builtin-command() {
    exec 2>&1
    cd /path
}
test-mock-cd-builtin-command-assert() {
    @dryrun cd /path
}

test-mock-echo-builtin-command() {
    unset -f echo
    @mock echo
    @type -t echo
    echo done
}
test-mock-echo-builtin-command-assert() {
    @echo function
    @dryrun echo done
}

test-mock-function-multiple-times() {
    @@mock random numbers === @echo num 1
    @@mock random numbers === @echo num 2
    @@mock random numbers === @echo num 3

    random
    random hello
    random numbers
    random numbers
    random numbers
    random numbers
}
test-mock-function-multiple-times-assert() {
    @dryrun random
    @dryrun random hello
    @cat << EOF
num 1
num 2
num 3
num 3
EOF
}

test-bach-should-ignore-comment() {
    only-you
    @comment hi
}
test-bach-should-ignore-comment-assert() {
    only-you
}

test-xargs-withoug-double-dashes() {
    @mock ls === @stdout foo bar
    ls | xargs -n1 do-something
}
test-xargs-withoug-double-dashes-assert() {
    @dryrun xargs -n1 do-something
}


test-xargs-with-double-dashes() {
    @mock ls === @stdout foo bar
    ls | xargs -- do-something
    ls | xargs -n1 -- do-something
    ls | xargs -I file -- do-something file with other parameters
}
test-xargs-with-double-dashes-assert() {
    do-something foo bar
    do-something foo
    do-something bar
    do-something foo with other parameters
    do-something bar with other parameters
}

test-bach-framework-set--e-should-work() {
    set -e

    do-this
    builtin false

    should-not-do-this

}
test-bach-framework-set--e-should-work-assert() {
    do-this
    @fail
}

test-bach-framework-set--o-pipefail-should-work() {
    set -o pipefail

    @false | do-this | @true
}
test-bach-framework-set--o-pipefail-should-work-assert() {
    do-this

    @fail
}

test-bach-framework-mock-builtin-trap-function() {
    @mock trap

    @type -t trap
    trap - ERR
}
test-bach-framework-mock-builtin-trap-function-assert() {
    @echo function
    @dryrun trap - ERR
}

test-bach-framework-should-clear-the-exit-trap-in-tests() {
    builtin trap -p EXIT
}
test-bach-framework-should-clear-the-exit-trap-in-tests-assert() {
    : do nothing here :
}

test-bach-framework-should-clear-the-exit-trap-in-assertion() {
    : do nothing here :
}
test-bach-framework-should-clear-the-exit-trap-in-assertion-assert() {
    builtin trap -p EXIT
}


test-bach-framework-set--u-should-work-in-tests() {
    set -ue
    unset foobar

    visit-an-undefined-variable "$foobar"

    should-not-show-this
}
test-bach-framework-set--u-should-work-in-tests-assert() {
    @fail
}


test-ASSERT-FAIL-bach-frmework-should-output-error-code-in-test() {
    @false
}


test-ASSERT-FAIL-bach-frmework-should-output-error-code-in-assertion() {
    @true
}
test-ASSERT-FAIL-bach-frmework-should-output-error-code-in-assertion-assert() {
    @fail
}


test-bach-framework-@fail-function-default-error-code-is-1() {
    set -euo pipefail
    @fail
}
test-bach-framework-@fail-function-default-error-code-is-1-assert() {
    builtin return 1
}


test-bach-framework-@fail-function-return-a-certain-error-code() {
    @fail 42
}
test-bach-framework-@fail-function-return-a-certain-error-code-assert() {
    builtin return 42
}


test-bach-framework-@fail-function-with-code-and-message() {
    @fail 43 "the error code is 43"
}
test-bach-framework-@fail-function-with-code-and-message-assert() {
    @out the error code is 43
    builtin return 43
}


test-bach-framework-@fail-function-with-error-message() {
    @fail "the error code is 1"
}
test-bach-framework-@fail-function-with-error-message-assert() {
    @out the error code is 1
    builtin return 1
}


function mock-bach-get-all-functions() {
    @mock bach-get-all-functions <<EOF
@echo declare -f gp
@echo declare -f test-bach-run-tests--get-all-tests-foo
@echo declare -f test-bach-run-tests--get-all-tests-bar
@echo declare -f test-bach-run-this
@echo declare -f test-bach-run-this-assert
@echo declare -f test-bach-run-this-too
@echo declare -f test-bach-run-tests--get-all-tests-bar2
@echo declare -f test-bach-run-tests--get-all-tests-bar-assert
EOF
}

test-bach-framework-only-run-a-certain-test() {
    export BACH_TESTS=bach-run-this

    unset -f bach-get-all-functions @shuf
    @mock @shuf === @sort
    mock-bach-get-all-functions
    bach-run-tests--get-all-tests
}
test-bach-framework-only-run-a-certain-test-assert() {
    @cat <<TESTS
test-bach-run-this
TESTS
}

test-bach-framework-uses-multi-tests-filters() {
    export BACH_TESTS='bach-run-this,bach-run-this-too'

    unset -f bach-get-all-functions @shuf
    @mock @shuf === @sort
    mock-bach-get-all-functions
    bach-run-tests--get-all-tests
}
test-bach-framework-uses-multi-tests-filters-assert() {
    @cat <<TESTS
test-bach-run-this
test-bach-run-this-too
TESTS
}

test-bach-framework-uses-multi-tests-filters-supports-glob() {
    export BACH_TESTS='bach-run-this*,*bar*'

    unset -f bach-get-all-functions @shuf
    @mock @shuf === @sort
    mock-bach-get-all-functions
    bach-run-tests--get-all-tests
}
test-bach-framework-uses-multi-tests-filters-supports-glob-assert() {
    @cat <<TESTS
test-bach-run-tests--get-all-tests-bar
test-bach-run-tests--get-all-tests-bar2
test-bach-run-this
test-bach-run-this-too
TESTS
}

test-bach-framework-filter-tests-no-matches() {
    export BACH_TESTS="you-can-not-find-me"

    unset -f bach-get-all-functions @shuf
    @mock @shuf === @sort
    mock-bach-get-all-functions
    bach-run-tests--get-all-tests
}
test-bach-framework-filter-tests-no-matches-assert() {
    @comment nothing here
}

test-bach-framework-filter-tests-by-glob() {
    export BACH_TESTS="bach-run-this*"

    unset -f bach-get-all-functions @shuf
    @mock @shuf === @sort
    mock-bach-get-all-functions
    bach-run-tests--get-all-tests
}
test-bach-framework-filter-tests-by-glob-assert() {
    @cat <<TESTS
test-bach-run-this
test-bach-run-this-too
TESTS
}

test-bach-framework-filter-tests-by-glob-two-stars() {
    export BACH_TESTS="*run-this*"

    unset -f bach-get-all-functions @shuf
    @mock @shuf === @sort
    mock-bach-get-all-functions
    bach-run-tests--get-all-tests
}
test-bach-framework-filter-tests-by-glob-two-stars-assert() {
    @cat <<TESTS
test-bach-run-this
test-bach-run-this-too
TESTS
}


test-ASSERT-FAIL-bach-framework-api-fail() {
    do-something
    @fail

    should-not-do-this
}
test-ASSERT-FAIL-bach-framework-api-fail-assert() {
    do-something
}


test-bach-framework-run-script-with-relative-path() {
    unset -f @source
    @mock @source

    BACH_STARTUP_PWD=/foo/bar/bach

    @run ../script.sh
}
test-bach-framework-run-script-with-relative-path-assert() {
    @dryrun @source /foo/bar/bach/../script.sh
}

test-bach-framework-run-script-with-absolute-path() {
    unset -f @source
    @mock @source

    BACH_STARTUP_PWD=/foo/bar/bach

    @run /awesome-bach/script.sh
}
test-bach-framework-run-script-with-absolute-path-assert() {
    @dryrun @source /awesome-bach/script.sh
}


test-bach-framework-run-script-with-mocking() {
    @mock do-this === @stdout "THIS"
    @mock do-that === @stdout "THAT"
    @run <(@cat <<SCRIPT
set -euo pipefail

do-this
do-something foo bar
do-that
SCRIPT
          )
}
test-bach-framework-run-script-with-mocking-assert() {
    @echo THIS
    @dryrun do-something foo bar
    @echo THAT
}


test-bach-framework-could-not-set-PATH-during-testing() {
    @real hostname
    PATH=/bin:/usr/bin

    ls -al -- should not show this command 2>&1
}
test-bach-framework-could-not-set-PATH-during-testing-assert() {
    /bin/hostname
    @fail
}


test-bach-framework-could-not-export-PATH() {
    export new_path=/bin:/usr/bin
    export PATH="$new_path"
    export FOOBAR=foobar
    ls -al "$FOOBAR"

    [[ "$PATH" == "$new_path" ]]
}
test-bach-framework-could-not-export-PATH-assert() {
    @dryrun ls -al foobar
    @fail
}


test-bach-framework-could-not-declare-PATH() {
    declare new_path=/bin:/usr/bin
    declare FOOBAR=foobar
    declare PATH="$new_path"

    ls -al "$FOOBAR"
    [[ "$PATH" == "$new_path" ]]
}
test-bach-framework-could-not-declare-PATH-assert() {
    @dryrun ls -al foobar

    @fail
}


test-bach-framework-could-not-set-PATH-for-a-command() {
    PATH=/bin:/usr/bin ls -al
}
test-bach-framework-could-not-set-PATH-for-a-command-assert() {
    @dryrun ls -al
}


test-bach-framework-could-not-set-PATH-by-full-path-of-env-command() {
    PATH=/bin:/usr/bin @env hostname
}
test-bach-framework-could-not-set-PATH-by-full-path-of-env-command-assert() {
    @fail 127
}


test-bach-framework-COULD-set-PATH-by-full-path-of-env-command() {
    @env PATH=/bin:/usr/bin hostname
}
test-bach-framework-COULD-set-PATH-by-full-path-of-env-command-assert() {
    /bin/hostname
}


test-bach-framework-one-pipeline-dryrun-if-no-mocking() {
    @mock receive-something
    @echo hello | receive-something done | @grep -q '^hello$'
}
test-bach-framework-one-pipeline-dryrun-if-no-mocking-assert() {
    receive-something done
}


test-bach-framework-one-pipeline-data-directly-if-default-mocking-behavior() {
    @mock receive-something done
    @echo hello | receive-something done
}
test-bach-framework-one-pipeline-data-directly-if-default-mocking-behavior-assert() {
    @stdout hello
}


test-bach-framework-one-pipeline-data-directly-if-customize-action() {
    @mock receive-something done === @stdout foobar
    @echo anything | receive-something done
}
test-bach-framework-one-pipeline-data-directly-if-customize-action-assert() {
    @echo foobar
}


test-bach-framework-two-pipelines-when-both-non-mocking-commands() {
    @mock first-cmd
    @mock second-cmd

    @echo something | first-cmd done | second-cmd too | @grep -q '^something$'
}
test-bach-framework-two-pipelines-when-both-non-mocking-commands-assert() {
    first-cmd done
    second-cmd too
}


test-bach-framework-two-pipelines-when-mock-the-first() {
    @mock this-is-a-mock command
    @mock this-non-mock

    @echo hello | this-is-a-mock command | this-non-mock command | @grep -q '^hello$'
}
test-bach-framework-two-pipelines-when-mock-the-first-assert() {
    this-non-mock command
}


test-bach-framework-two-pipelines-when-mock-the-second() {
    @mock this-is-a-mock command
    @mock this-non-mock

    @echo due to subprocesses running in background | this-non-mock command goes first | this-is-a-mock command
}
test-bach-framework-two-pipelines-when-mock-the-second-assert() {
    this-non-mock command goes first
    @stdout "due to subprocesses running in background"
}


test-bach-framework-two-pipelines-when-mock-the-both() {
    @mock this-is-a-mock command
    @mock another-mock command

    @echo hello | this-is-a-mock command | another-mock command
}
test-bach-framework-two-pipelines-when-mock-the-both-assert() {
    @stdout hello
}


test-bach-framework-multi-pipelines() {
    @mock first
    @mock second === two
    @mock third 3

    @echo gone | first non mocking | second | third 3
}
test-bach-framework-multi-pipelines-assert() {
    @dryrun first non mocking
    two
}


test-bach-framework-handles-an-empty-command() {
    "" 7>&1 | @grep -Fq 'found an empty command'
    @assert-success
}


test-bach-framework-is_function() {
    function this_is_a_function() {
        : do nothing
    }

    bach--is-function this_is_a_function
    @assert-success
}


test-bach-framework-is_function-2() {
    this_is_a_variable=some_value

    bach--is-function this_is_a_variable
}
test-bach-framework-is_function-2-assert() {
    @fail
}


test-bach-framework-@assert-equals-no-parameters() {
    @assert-equals
}
test-bach-framework-@assert-equals-no-parameters-assert() {
    @fail
}


test-bach-framework-@assert-equals-pass-one-parameter() {
    @assert-equals only-one
}
test-bach-framework-@assert-equals-pass-one-parameter-assert() {
    @fail
}


test-bach-framework-@assert-equals-integers() {
    @assert-equals 9 9
}


test-bach-framework-@assert-equals-strings() {
    @assert-equals "hello world" "hello world"
}


test-bach-framework-@assert-equals-variables() {
    foo="hello world"
    bar="hello world"
    @assert-equals "$foo" "$bar"
}


test-ASSERT-FAIL-bach-framework-each-test-case-does-not-have-an-assertion() {
    @echo Every test case must have an assertion
}

test-ASSERT-FAIL-bach-framework-each-test-case-has-a-failed-assertion() {
    @echo Every test case must have an assertion, it is fail
    @assert-equals "Answer to the Ultimate Question of Life, the Universe, and Everything" 42
}

test-bach-framework-each-test-case-has-a-successful-assertion() {
    @echo Every test case must have an assertion, it is success
    @assert-success
}

test-ASSERT-FAIL-bach-framework-each-test-case-has-assert-fail() {
    @echo Every test case must have an assertion
    @assert-fail
}


test-bach-framework-API-@assert-fail() {
    @echo Every test case must have an assertion
    @false
    @assert-fail
}
test-bach-framework-API-@assert-fail-assert() {
    @echo Every test case must have an assertion
    @cat <<EOF
## BACH: [assert-equals] expected: 1
##                         actual: 1
EOF
}


test-bach-framework-API-@assert-fail-2() {
    @echo Every test case must have an assertion
    @assert-fail
}
test-bach-framework-API-@assert-fail-2-assert() {
    @echo Every test case must have an assertion
    @cat <<EOF
Assert Failed:
     Expected: <non-zero>
      But got: 0
EOF
    builtin return 1
}


test-bach-framework-API-@assert-success() {
    @echo Every test case must have an assertion
    @assert-success
}
test-bach-framework-API-@assert-success-assert() {
    @echo Every test case must have an assertion
    @cat <<EOF
## BACH: [assert-equals] expected: 0
##                         actual: 0
EOF
}


test-ASSERT-FAIL-bach-framework-one-success-and-one-fail-should-be-fail() {
    @echo one success and one fail
    @assert-success
    @assert-fail
}


test-ASSERT-FAIL-bach-framework-one-fail-and-one-success-should-be-fail() {
    @echo one success and one fail
    @assert-fail
    @assert-success
}
