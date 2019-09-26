#!/usr/bin/env bash
set -uo pipefail

unset BACH_ASSERT_DIFF BACH_ASSERT_DIFF_OPTS
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin

bash_bin="$BASH"

case "$(uname)" in
    Darwin)
        if ! brew list --full-name --versions bash &>/dev/null; then
            brew install bash
        fi
        if [[ "$BASH" == /bin/bash ]]; then
            bash_bin="$(brew --prefix)"/bin/bash
        fi
        ;;
esac

"$bash_bin" --version

function out() {
    printf "\n\e[1;37;497;m%s\e[0;m\n" "$@"
} >&2

function err() {
    printf "\n\e[1;37;41;m%s\e[0;m\n\n" "$@"
} >&2

retval=0
for file in tests/*.test.sh examples/learn*; do
    out "Running $file"
    if grep -E "^[[:blank:]]*BACH_TESTS=.+" "$file"; then
        err "Found defination of BACH_TESTS in $file"
        retval=1
    fi
    "$bash_bin" -euo pipefail "$file" || retval=1
done

if [[ "$retval" -ne 0 ]]; then
    echo "Test failed!"
fi

exit "$retval"
