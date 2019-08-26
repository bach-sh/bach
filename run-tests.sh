#!/usr/bin/env bash
set -uo pipefail

PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin

bash_bin=/bin/bash

case "$(uname)" in
    Darwin)
        if ! brew list --full-name --versions bash &>/dev/null; then
            brew install bash
        fi
        bash_bin="$(brew --prefix)"/bin/bash
        ;;
esac

"$bash_bin" --version

retval=0
for file in examples/{test,learn}*; do
    "$bash_bin" -euo pipefail "$file" || retval=1
done

exit "$retval"
