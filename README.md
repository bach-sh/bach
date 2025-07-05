# Bach Unit Testing Framework

[![Build Status](https://travis-ci.org/bach-sh/bach.svg)](https://travis-ci.org/bach-sh/bach)
[![GitHub Actions](https://github.com/bach-sh/bach/workflows/Testing%20Bach/badge.svg)](https://github.com/bach-sh/bach)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: MPL v2](https://img.shields.io/badge/License-MPL%20v2-blue.svg)](https://www.mozilla.org/en-US/MPL/2.0/)

[![Run on Repl.it](https://repl.it/badge/github/bach-sh/bach)](https://repl.it/github/bach-sh/bach)


## Bach

Bach is a Bash testing framework, can be used to test scripts that contain dangerous commands like `rm -rf /`. No surprises, no pain.

- Website: https://bach.sh
- Repo: https://github.com/bach-sh/bach
- [查看本文档的中文版](README-cn.md)


## Getting Started

Bach Unit Testing Framework is a **real** unit testing framework. All commands in the `PATH` environment variable become external dependencies of bash scripts being tested. No commands can be actually executed. In other words, all commands in Bach test cases are **dry run**. Because that unit tests should verify the behavior of bash scripts, not test commands. Bach Testing Framework also provides APIs to mock commands.

### Prerequisites

- [Bash](https://www.gnu.org/software/bash/) v4.3+
- [Coreutils](https://www.gnu.org/software/coreutils/coreutils.html) (*GNU/Linux*)
- [Diffutils](https://www.gnu.org/software/diffutils/diffutils.html) (*GNU/Linux*)

### Installing

Installing Bach Testing Framework is very simple. Download [bach.sh](https://github.com/bach-sh/bach/raw/master/bach.sh) to your project, use the `source` command to import `bach.sh`.

For example:

    source path/to/bach.sh

#### A complete example

    #!/usr/bin/env bash
    source bach.sh

    test-rm-rf() {
        # Write your test case

        project_log_path=/tmp/project/logs
        rm -rf "$project_log_ptah/" # Typo here!
    }
    test-rm-rf-assert() {
        # Verify your test case
        rm -rf /   # This is the actual command to run on your host!
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

See [tests/bach-testing-framework.test.sh](tests/bach-testing-framework.test.sh) for more examples.

#### On Windows
Make sure to use for shebang
```
#!/bin/bash
```
and not
```
#!/bin/sh
```

If on Cygwin (as opposed to Git Bash), the end of line sequence of `bach.sh` should be `LF`.

### Write test cases

Unlike the other testing frameworks, A standard test case of Bach is composed of two Bash functions. One is for running tests, the other is for asserting. Bach will run the two functions separately and then compare whether the same sequence of commands will be executed in both functions. The name of a testing function must start with `test-`, the name of the corresponding asserting function ends with `-assert`.

For example:

    source bach.sh

    test-rm-rf() {
        project_log_path=/tmp/project/logs
        sudo rm -rf "$project_log_ptah/" # Typo!
        # An undefined bash variable is an empty string, which can be a serious problem!
    }
    test-rm-rf-assert() {
        sudo rm -rf /
    }

Bach will run the two functions separately, `test-rm-rf` and `test-rm-rf-assert`. In the testing function, `test-rm-rf`, the final actual command to be executed is `sudo rm -rf "/"`. It's the same as the asserting function `test-rm-rf-assert`. So this test case passes.

If Bach does not find the asserting function for a testing function. It will try to use a traditional test method. In this case, the testing function must have a call to assert the APIs. Otherwise, the test case will fail.

For example:

    test-single-function-style() {
        declare i=2
        @assert-equals 4 "$((i*2))"
    }

If Bach does not find the corresponding asserting function and there is no assertion API call in the testing function, the test case must fail.

If the name of a test case starts with `test-ASSERT-FAIL`, it means that the asserting result of this test case is reversed. That is, if the asserting result is successful, the test case fails, if the asserting result fails, the test case is successful.

The assertion APIs of Bach Testing Framework:

- `@assert-equals`
- `@assert-fail`
- `@assert-success`

### Mock commands

There are mock APIs in the Bach test framework that can be used to mock commands and scripts.

The Mock APIs:

- `@mock`
- `@ignore`
- `@mockall`
- `@mocktrue`
- `@mockfalse`
- `@@mock`

But it doesn't allow to mock the following built-in commands in Bach Testing Framework:

- `builtin`
- `declare`
- `eval`
- `set`
- `unset`
- `true`
- `false`
- `read`

Test cases will fail if you attempt to mock these built-in commands. If they are needed in the script under test, we can extract a new function which contains the built-in commands in our scripts, and then use Bach to mock this new function.

### Run the actual commands in Bach

In order to make test cases fast, stable, repetitive, and run in random order. We should write unit-testing cases and avoid calling real commands. But Bach also provides a set of APIs for executing real commands.

Bach mocks all commands by default. If it is unavoidable to execute a real command in a test case, Bach provides an API called `@real` to execute the real command, just put `@real` at the beginning of commands.

Bach also provides APIs for commonly used commands. The real commands for these APIs are obtained from the system's PATH environment variable before Bach starts.

These common used APIs are:

- `@cd`
- `@command`
- `@echo`
- `@exec`
- `@false`
- `@popd`
- `@pushd`
- `@pwd`
- `@set`
- `@trap`
- `@true`
- `@type`
- `@unset`
- `@eval`
- `@source`
- `@cat`
- `@chmod`
- `@cut`
- `@diff`
- `@find`
- `@env`
- `@grep`
- `@ls`
- `@shasum`
- `@mkdir`
- `@mktemp`
- `@rm`
- `@rmdir`
- `@sed`
- `@sort`
- `@tee`
- `@touch`
- `@which`
- `@xargs`

`command` and `xargs` are a bit special. Bach mocks both commands by default to make the similar behavior of themselves.

In Bach Testing Framework the `xargs` is a mock function. It's behavior is similar to the real `xargs` command if you put `--` between `xargs` and the command. But the commands to be executed by  `xargs` are dry run.

For examples:

    test-xargs-no-dash-dash() {
        @mock ls === @stdout foo bar

        ls | xargs -n1 rm -v
    }
    test-xargs-no-dash-dash-assert() {
        xargs -n1 rm -v
    }


    test-xargs() {
        @mock ls === @stdout foo bar

        ls | xargs -n1 -- rm -v
    }
    test-xargs-assert() {
        rm -v foo
        rm -v bar
    }


    test-xargs-0() {
        @mock ls === @stdout foo bar

        ls | xargs -- rm -v
    }
    test-xargs-0-assert() {
        rm -v foo bar
    }

We can also mock the test command `[ ... ]`. But it will keep the original behavior if we don't mock it.

For examples:

    test-if-string-is-empty() {
        if [ -n "original behavior" ] # We did not mock it, so this test keeps the original behavior
        then
            It keeps the original behavior by default # We should see this
        else
            It should not be empty
        fi

        @mockfalse [ -n "Non-empty string" ] # We can reverse the test result by mocking it

        if [ -n "Non-empty string" ]
        then
            Non-empty string is not empty # No, we cannot see this
        else
            Non-empty string should not be empty but we reverse its result
        fi
    }
    test-if-string-is-empty-assert() {
        It keeps the original behavior by default

        Non-empty string should not be empty but we reverse its result
    }

    # Mocking the test command `[ ... ]` is useful
    # when we want to check whether a file with absolute path exists or not
    test-a-file-exists() {
        @mocktrue [ -f /etc/an-awesome-config.conf ]
        if [ -f /etc/an-awesome-config.conf ]; then
            Found this awesome config file
        else
            Even though this config file does not exist
        fi
    }
    test-a-file-exists-assert() {
        Found this awesome config file
    }


### Configure Bach

There are some environment variables starting with `BACH_` for configuring Bach Testing Framework.

- `BACH_DEBUG`
  The default is `false`. `true` to enable Bach's `@debug` API.
- `BACH_COLOR`
  The default is `auto`. It can be `always` or `no`.
- `BACH_TESTS`
  It is empty to allow all test cases. You can use glob wildcards to match the test cases to execute.
- `BACH_DISABLED`
  The default is `false`. `true`  to disable Bach Testing Framework.
- `BACH_ASSERT_DIFF`
  The default is the first `diff` command found in the original `PATH` environment variable of the system. Used to compare the execution results of testing functions and asserting functions.
- `BACH_ASSERT_DIFF_OPTS`
  The default is `-u` for the `$BACH_ASSERT_DIFF` command.

## Limitation of Bach

### Cannot block absolute path command calls

In this case, the OS runs the command directly, and does not interact with Bash(or Shell). Bach cannot intercept such commands. We can wrap this kind of commands in a new function, and then use the `@mock` API to mock the function.

### Prohibit resetting the PATH environment variable

Because Bach wants to intercept all command calls, the `PATH` is set to read-only to avoid resetting its value.

In the case that PATH needs to be re-assigned, it is recommended to use the `declare` builtin command in our scripts to avoid errors caused by resetting a read-only environment variable.

### Special Handling of I/O Redirection in Bach

Bach’s mocked commands already support reading from standard input and working with pipelines.
However, I/O redirection using operators like `>` or `>>` cannot be intercepted by Bach due to the limitation of Bash.

A common workaround is to wrap the redirection in a function or use a different command, such as replacing write-to-file redirection with the `tee` command.
For example, instead of writing `your-cmd > path/to/file`, you can write `your-cmd | tee path/to/file >/dev/null`.

You can also use the `@capture` API to indicate that a command will receive input data, and then use the `@assert-capture` API in your assertion function to verify that the command received the expected data.
See the examples below:

    test-api-capture() {
        @capture foobar foo bar

        @echo hello | foobar foo bar
    }
    test-api-capture-assert() {
        @assert-capture foobar foo bar <<< hello
    }

    test-api-capture-heredoc() {
        @capture foobar foo bar

        foobar foo bar <<\EOF
    the first line
    the 2nd line
    the 3rd line
    EOF
    }
    test-api-capture-heredoc-assert() {
        @echo "the first line
    the 2nd line
    the 3rd line" | @assert-capture foobar foo bar
    }

### All command in the pipeline must be mocked

The pipeline commands in Bash are running in sub-processes. Test cases may not be stable if we don't use `@mock` API to mock these pipeline commands.

### Using unicode character `∅` (empty set) to indicate an empty string

Because there is no way to display an empty string on a terminal. Bach chooses the red empty set symbol `∅` to indicate it's an empty string.

When we see this red `∅` in test results, it means that the parameter is actually an empty string.

```
-foobar  ∅
+foobar
```

## Bach APIs

The names of all APIs provided in the Bach testing framework start with `@`.

### @allow-real

Allow a specific command to run for real in the test, instead of being mocked or dry-run.
When this API is called, the specified command will be executed as a real system command.
A message will be shown in the test output to indicate which command is allowed to run.

Usage:

    @allow-real [command and arguments...]

Example:

    test-allow-real-grep() {
        @allow-real grep -i hello
        grep -i hello <<< "Hello, Bach"
        grep -i hello <<< "Goodbye"
    }
    test-allow-real-grep-assert() {
        @stdout "Hello, Bach"
        @fail
    }

Output:

    ok 1 - allow real grep
    # [ALLOW-REAL] grep -i hello

When you use `@allow-real grep -i hello`, the command `grep -i hello` will really run during the test.
Bach will display a message like `# [ALLOW-REAL] grep -i hello` in the test result to make it easy to track which commands were allowed to run.

### @assert-capture

This API is designed specifically for validation functions to verify the input read by a command.

To use this API, follow these steps:

1. In the test execution function, use the `@capture` API to record the input of the command.
2. In the assertion function, use the `@assert-capture` API to validate if the captured data matches the expected input.

Example:

    test-capture() {
        # Record the data read by the command `foobar foo`
        @capture foobar foo
        echo hello | foobar foo  # The command `foobar foo` reads data from the pipeline
    }

    test-capture-assert() {
        # Verify that the command `foobar foo` reads the data "hello"
        @assert-capture foobar foo <<< "hello"
    }

### @assert-equals

    @assert-equals "hello world" "HELLO WORLD"
    @assert-equals 1 1

### @assert-fail

    [[ 1 -eq 3 ]]
    @assert-fail

### @assert-success

    [[ 0 -eq 0 ]]
    @assert-success

### @capture

This API is used to record the data read by a command, including input received through pipelines, Here Documents, and other I/O redirection methods.

Examples: please refer to the `@assert-capture` API.

### @comment

Output comments in the test output, but Bach will ignore these comments.

### @debug

### @die

Terminate the current run immediately

### @do-not-panic

Don't panic.

This API has the following aliases:
- `donotpanic`
- `dontpanic`
- `do-not-panic`
- `dont-panic`
- `do_not_panic`
- `dont_panic`

### @do-nothing

Do nothing.

Usually this API is used only in asserting functions to verify that no any commands to be executed in testing functions.

For example:

    test-nothing() {
        declare i=9
        if [[ "$i" -eq 0 ]]; then
            do-something
        fi
    }
    test-nothing-assert() {
        @do-nothing
    }

### @dryrun

Bach uses `@dryrun` API to dry run commands by default. But if you want to dry run a mocked command, just put `@dryrun` in front of this mocked command.

For example:

    test-dryrun() {
        @mock ls === @stdout file1 file2 # mock `ls` command
        ls # outputs file1 file2
        @dryrun ls # Dry run `ls` command
    }
    test-dryrun-assert() {
        @out file1
        @out file2
        ls # @dryrun ls
    }

### @err

Output error message on stderr console

### @ignore

    test-ignore-echo() {
        @ignore echo

        echo Updating APT caches
        apt-get update
    }
    test-ignore-echo-assert() {
        apt-get update
    }

### @load_function

Loading a function definition from a script.

    test-gp() {
        @load_function ./examples/example-functions gp

        gp -f
    }
    test-gp-assert() {
        git push -f origin master
    }

### @mock

Mocks the execution of commands or scripts. If the command requires different parameters when executed, multiple mock APIs `@@mock` are needed.

Usage: After `@mock`, specify the complete command to be mocked, and after `===`, define the mock behavior or output. For example: `@mock your-command param1 param2 === @stdout out1 out2`

If `===` is omitted, the default behavior is to invoke the `@dryrun` API to output the command. This method is commonly used to mock pipeline commands to prevent random order assertions. If you need to pass the input from the pipeline to the output, use the `@mockpipe` API.

Note:
- To mock the execution of a script, the script's path must be a relative path, as you cannot mock scripts with absolute paths.
- If a command is mocked multiple times, only the last mock will take effect.

Example:

#### Mocking a command

    @mock ls file1 === @stdout file2

    ls file1 # This will output file2 in the console. It lists the file `file1`, but displays `file2`. Weird, right?

    ls foo bar # Since the `ls` command with these specific parameters hasn't been mocked, `ls foo bar` needs to be asserted.

#### Mocking without specifying behavior or output

    # Mocking all commands in the pipeline ensures that during assertion, the execution order of commands is consistent with the pipeline order.

    @mock foo param1 param2
    @mock bar param1
    @mock foobar

    foo param1 param2 | bar param1 | foobar

#### Mock commands with complex implementations

For example:

    test-mock-foobar() {
      @mock foobar <<<\CMD
        if [[ "$var" -eq 1 ]]; then
          @stdout one
        else
          @stdout others
        fi
    CMD

      var=1 foobar
      foobar
    }
    test-mock-foobar() {
      @out one
      @out others
    }

### @@mock

Mock the same command multiple times and return different values for each run.

For example:

    test-mock-function-multiple-times() {
        @@mock random numbers === @out num 1
        @@mock random numbers === @out num 22
        @@mock random numbers === @out num 333

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
    num 22
    num 333
    num 333
    EOF
    }

### @mockall

Mock many simple commands

### @mocktrue

Mock the return code of a command as successful.

### @mockfalse

Mock the return code of a command as non-zero value.

### @mockpipe

Mock the command in a pipeline: When a mocked command is called within the pipeline, the input will be output unchanged. Commands mocked with `@mock` by default will discard the data in the pipeline.

Example:

    @mock say hello === @echo hello

    @mockpipe a_command_in_a_pipeline some parameters
    say hello | a_command_in_a_pipeline some parameters # This pipeline command will output "hello"

    @mock foobar foo bar
    say hello | foobar foo bar # This pipeline command will have no output because the default mocked command `foobar foo bar` will discard the data in the pipeline

### @mock-regex

Mocks a command, similar to `@mock`, but it supports using regular expressions to match command arguments. The `^` symbol matches the start of the first argument. Multiple arguments are joined by spaces and matched against the regular expression as a whole.

Example:

    # 模拟判断 [ -f anyfile ] 都会返回成功
    @mock-regex [ -f [^ ]* ] === @true
    if [ -f config ]; then
      echo Found config file
    fi

### @out

Output to the stdout console.

### @real

Executing the real command.

### @run

Executing the script to be tested.

#### `@setup`

Executed at the beginning of the testing functions and the asserting functions.

Note: It doesn't make sense to run mock in asserting functions, so it's forbidden to mock any commands in asserting functions.

We cannot mock commands in `@setup` API.

example:

    @setup {
        @echo executing in both the testing function and the asserting function.
    }

### @setup-assert

Executing at the beginning of all asserting functions.

Note: the test cases will fail if we mock any commands inside `@setup-assert`

For example:

    @setup-assert {
        @echo executing in the asserting functions
    }

### @setup-test

Executed at the beginning of all testing functions.

This is the only place that allows mock commands outside testing functions.

For example:

    @setup-test {
        @echo executing in the testing functions
    }

### @stderr

Output content to the stderr console, one line per parameter.

### @stdout

Output content to the stdout console, one line per parameter.

## Learn Bash Programming with Bach

    test-learn-bash-no-double-quote-star() {
        @touch bar1 bar2 bar3 "bar*"

        function cleanup() {
            rm -rf $1
        }

        # We want to remove the file "bar*", not the others
        cleanup "bar*"
    }
    test-learn-bash-no-double-quote-star-assert() {
        # Without double quotes, all bar files are removed!
        rm -rf "bar*" bar1 bar2 bar3
    }

    test-learn-bash-double-quote-star() {
        @touch bar1 bar2 bar3 "bar*"

        function cleanup() {
            rm -rf "$1"
        }

        # We want to remove the file "bar*", not the others
        cleanup "bar*"
    }
    test-learn-bash-double-quote-star-assert() {
        # Yes, with double quotes, only the file "bar*" is removed
        rm -rf "bar*"
    }

## Roadmap

- a command line tool
- run inside docker containers
n
## Clients

* BMW Group
* Huawei (华为)

## Versioning

The latest version of Bach is 0.7.1, See [Bach Releases](https://github.com/bach-sh/bach/releases) for more.

## Author

* **Chai Feng** [github.com/chaifeng](https://github.com/chaifeng), [chaifeng.com](https://chaifeng.com)

## Licenses

Bach Testing Framework is dual licensed under:

- [GNU General Public License v3.0](LICENSE.GPL-3.0)
- [Mozilla Public License 2.0](LICENSE.MPL-2.0)

See [LICENSE](LICENSE) for more.
