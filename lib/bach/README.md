# Bach Testing Framework

## Bach

Bach is a unit testing framework used for testing Bash scripts.

It's part of Shell Common Functions Library

## Requires

- Bash v4.3+

## Examples

    #!/usr/bin/env bash
    set -euo pipefail
    source <(path/to/common-functions-lib/cflib-import.sh)
    require bach

    test-rm-rf() {
        # Write your test case
    
        project_log_path=/tmp/project/logs
        sudo rm -rf "$project_log_ptah/" # Typo here!
    }
    test-rm-rf-assert() {
        # Verify your test case
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
    
### More Examples

[examples/test-bach-unit-testing-framework.sh](../../examples/test-bach-unit-testing-framework.sh)

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
