#!/usr/bin/env bash
# Using Bach to learn Bash programming

## Using Shell Common Functions Library to import Bach Testing Framework

    declare -grx self="$(readlink -f "${BASH_SOURCE}")"
    source <("${self%/*/*}"/cflib-import.sh)
    require bach

## Why double quotes are so important to Bash?

### Without double quotes, a Bash variable can be expanded again

    test-learn-bash-programming:-no-double-quotes() {

#### This example function that passes the accepted argument to the no-double-quote command, but does not include $@ in double quotes.

        function foo() {
            no-double-quote $@
        }

#### Invoke the function with a parameter "a b c d"

        foo "a b c d"
    }

#### But the command `no-double-quote` got FOUR parameters, which are "a", "b", "c", "d"

    test-learn-bash-programming:-no-double-quotes-assert() {
        no-double-quote a b c d
    }

### Usually in Bash programming, variables should use double quotes unless you know exactly what you are doing

    test-learn-bash-programming:-using-double-quotes() {

#### This example function that passes the accepted argument to the no-double-quote command, and includes $@ in double quotes.

        function foo() {
            double-quotes "$@"
        }

#### Invoke the function with a parameter "a b c d"

        foo "a b c d"
    }

#### The command 'double-quotes' got the correct parameter

    test-learn-bash-programming:-using-double-quotes-assert() {
        double-quotes "a b c d"
    }

### Forgetting double quotes can lead to serious problems

    test-learn-bash-programming:-forgeting-double-quotes-can-lead-to-serious-problems() {

#### Assume we have four files, which are "bar1", "bar2", "bar3" and "bar*"

        @touch bar1 bar2 bar3 "bar*"

#### Now we have a function to delete files, but forgot to include $1 in double quotes

        function cleanup() {
            rm -rf $1
        }

#### When we use the function to delete file "bar*", not any others

        cleanup "bar*"
    }
    test-learn-bash-programming:-forgeting-double-quotes-can-lead-to-serious-problems-assert() {

#### Because there are no double quotes, the parameter will be expanded in the function, and all "bar" files are deleted

        rm -rf "bar*" bar1 bar2 bar3
    }

### Double quotes are so important to Bash variables

    test-learn-bash-programming:-double-quotes-are-important-to-bash-variables() {

#### Assume we have four files

        @touch bar1 bar2 bar3 "bar*"

#### We write a funciton to delete files, and use the double quotes correctly

        function cleanup() {
            rm -rf "$1"
        }

#### When we use the function to delete the file "bar*"

        cleanup "bar*"
    }
    test-learn-bash-programming:-double-quotes-are-important-to-bash-variables-assert() {

#### Because there are double quotes, only the file "bar*" is deleted

        rm -rf "bar*"
    }
