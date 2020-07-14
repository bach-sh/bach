#!/bin/sh
set -ue
[ -z "${DEBUG:-}" ] || set -x

unset BACH_ASSERT_DIFF BACH_ASSERT_DIFF_OPTS
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin

OS_NAME="$(uname)"
if [ -e /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="${OS_NAME}-${ID}-${VERSION_ID}"
fi
case "$OS_NAME" in
    Darwin)
        if ! brew list --full-name --versions bash &>/dev/null; then
            brew install bash
        fi
        bash_bin="$(brew --prefix)"/bin/bash
        ;;
    FreeBSD)
        export PATH="/usr/local/sbin:$PATH"
        export ASSUME_ALWAYS_YES=yes
        pkg_install_bash="pkg bootstrap -fy; hash -r; pkg update -f; pkg install -y bash"
        if ! hash bash; then
            if [ "$(id -u)" -gt 0 ] && hash sudo; then
                sudo /bin/sh -c "$pkg_install_bash"
            else
                /bin/sh -c "$pkg_install_bash"
            fi
        fi
        ;;
    Linux-alpine-*)
        apk update
        apk add coreutils diffutils
        ;;
esac

if [ -z "${bash_bin:-}" ]; then
    bash_bin="$(which bash)"
fi

echo "Bash: $bash_bin"
test -n "$bash_bin"
"$bash_bin" --version

err() {
  echo "$*" >&2
}

set +e
retval=0
cd "$(dirname "$0")"
for file in tests/*.test.sh examples/learn*; do
    echo "Running $file"
    if grep -E "^[[:blank:]]*BACH_TESTS=.+" "$file"; then
        err "Found defination of BACH_TESTS in $file"
        retval=1
    fi
    "$bash_bin" -euo pipefail "$file" || retval=1
done

if [ "$retval" -ne 0 ]; then
    err "Test failed!"
fi

exit "$retval"
