#!/usr/bin/env bash
declare -grx self="$(realpath "${BASH_SOURCE}")"
source <("${self%/*/*}"/cflib-import.sh)
require bach

#declare -a BACH_ASSERT_DIFF_OPTS=(-w -y)
export BACH_DEBUG=true

test-rm--rf() {
    project_log_path=/tmp/project/logs
    sudo rm -rf "$project_log_ptah/" # Typo here!
}
test-rm--rf-assert() {
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
    @false
}

test-mock-command-which-something() {
    @mock command which something === fake-something
    command which something
    PATH=/bin:/usr/bin command which hostname
}
test-mock-command-which-something-assert() {
    fake-something
    @echo /bin/hostname
}

test-@real-function() {
    @mock command which md5sum === fake-md5sum
    @real md5sum --version
    @real diff --version
}
test-@real-function-assert() {
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

    @mock ls file1 file2 === file2 file1
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
    @false
}


test-gp-running-not-inside-a-valid-git-repo-again() {
    load-gp
    init-current-working-dir-is-not-a-repo

    set -eu
    gp origin
}
test-gp-running-not-inside-a-valid-git-repo-again-assert() {
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
    return 1
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
    @assert-fail Should not go here
    ./cannot-mock-existed-script foo bar    2>&1
}
test-cannot-mock-existed-script-assert() {
    @echo 'Cannot mock an existed path: ./cannot-mock-existed-script'
    return 1
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
    exec 2>&1
    @echo cd /path
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

test-bach-framework-set--e-does-not-work-due-to-a-known-limitation() {
    set -e

    do-this
    builtin false

    due-to-a-known-limitation set -e does not work in tests

}
test-bach-framework-set--e-does-not-work-due-to-a-known-limitation-assert() {
    do-this

    due-to-a-known-limitation set -e does not work in tests
    #
    # See:
    #   - http://austingroupbugs.net/view.php?id=537
    #   - https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_25
    #
    # set
    #     -e
    #     When this option is on, when any command fails (for any of the reasons listed in Consequences of Shell Errors or by returning an exit status greater than zero), the shell immediately shall exit, as if by executing the exit special built-in utility with no arguments, with the following exceptions:
    #     The failure of any individual command in a multi-command pipeline shall not cause the shell to exit. Only the failure of the pipeline itself shall be considered.
    #
    #     The -e setting shall be ignored when executing the compound list following the while, until, if, or elif reserved word, a pipeline beginning with the ! reserved word, or any command of an AND-OR list other than the last.
    #
    #     If the exit status of a compound command other than a subshell command was the result of a failure while -e was being ignored, then -e shall not apply to this command.
    #
    #     This requirement applies to the shell environment and each subshell environment separately. For example, in:
    #
    #     set -e; (false; echo one) | cat; echo two
    #
    #     the false command causes the subshell to exit without executing echo one; however, echo two is executed because the exit status of the pipeline (false; echo one) | cat is zero.
}
