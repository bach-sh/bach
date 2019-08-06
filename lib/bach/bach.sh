# -*- mode: sh -*-
set -euo pipefail

export BACH_COLOR="${BACH_COLOR:-auto}"

shopt -s expand_aliases
export BACH_OS_ORIGIN_PATH="$PATH"
export PS4='+ ${FUNCNAME:-}:${LINENO} '

function @out() {
    if [[ ! -t 0 ]]; then
        while IFS=$'\n' read -r line; do
            printf "%s\n" "${*}$line"
        done
    elif [[ "$#" -gt 0 ]]; then
        printf "%s\n" "$*"
    else
        printf "\n"
    fi
} 8>/dev/null
export -f @out

function @err() {
    @out "$@"
} >&2
export -f @err

function @die() {
    @out "$@"
    exit 1
} >&2
export -f @die

if [[ -z "${BASH_VERSION:-}" ]] || [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    @die "Bach Testing Framework only support Bash v4+!"
fi

if [[ "${BACH_DEBUG:-}" != true ]]; then
    function @debug() {
        :
    }
else
    exec 8>&2
    function @debug() {
        @printf '[DEBUG] %s\n' "$*"
    } >&8
fi
export -f @debug

function bach-real-path() {
    PATH="$BACH_OS_ORIGIN_PATH" command which "$1"
}
export -f bach-real-path

for name in cd command echo eval exec false popd pushd pwd source trap true type; do
    eval "function @${name}() { builtin $name \"\$@\"; } 8>/dev/null; export -f @${name}"
done

for name in echo pwd test; do
    declare -grx "_${name}"="$(bach-real-path "$name")"
done

declare -a bach_core_utils=(cat chmod cut diff find env grep ls md5sum mkdir mktemp rm rmdir sed shuf sort tee touch which xargs)

for name in "${bach_core_utils[@]}"; do
    declare -grx "_${name}"="$(bach-real-path "$name")"
    eval "[[ -n \"\$_${name}\" ]] || @die \"Fatal, CAN NOT find '$name' in \\\$PATH\"; function @${name}() { \"\${_${name}}\" \"\$@\"; } 8>/dev/null; export -f @${name}"
done
unset name

function bach-real-command() {
    declare name="$1"
    if [[ "$name" == */* ]]; then
        @echo "$@"
        return
    fi
    declare -a cmd
    cmd=("$(bach-real-path "$1")" "${@:2}")
    @debug "[REAL-CMD]" "${cmd[@]}"
    "${cmd[@]}"
}
export -f bach-real-command
alias @real=bach-real-command

function bach-get-all-functions() {
    declare -F
}
export -f bach-get-all-functions

function bach--skip-the-test() {
    declare test="$1"
    if [[ -n "${BACH_TESTS:-}" ]]; then
        [[ "$test" == $BACH_TESTS ]] ||
            [[ "$test" == test-$BACH_TESTS ]]
    fi
}
export -f bach--skip-the-test

function bach-run-tests--get-all-tests() {
    bach-get-all-functions | @shuf | while read -r _ _ name; do
        [[ "$name" == test?* ]] || continue
        [[ "$name" == *-assert ]] && continue
        bach--skip-the-test "$name" || continue
        printf "%s\n" "$name"
    done
}

function bach-run-tests() {
    set -euo pipefail

    if [[ "${BACH_ASSERT_IGNORE_COMMENT}" == true ]]; then
        BACH_ASSERT_DIFF_OPTS+=(-I "^##BACH: ")
    fi
    @mockall cd echo

    declare color_ok color_err color_end
    if [[ "$BACH_COLOR" == "always" ]] || [[ "$BACH_COLOR" != "no" && -t 1 && -t 2 ]]; then
        color_ok="\e[1;32m"
        color_err="\e[1;31m"
        color_end="\e[0;m"
    else
        color_ok=""
        color_err=""
        color_end=""
    fi
    declare name friendly_name testresult
    declare -i total=0 error=0
    declare -a all_tests
    mapfile -t all_tests < <(bach-run-tests--get-all-tests)
    @echo "1..${#all_tests[@]}"
    for name in "${all_tests[@]}"; do
        # @debug "Running test: $name"
        friendly_name="${name/#test-/}"
        friendly_name="${friendly_name//-/ }"
        friendly_name="${friendly_name//  / -}"
        : $(( total++ ))
        testresult="$(@mktemp)"
        if assert-execution "$name" &>"$testresult"; then
            printf "${color_ok}ok %d - %s${color_end}\n" "$total" "$friendly_name"
        else
            : $(( error++ ))
            printf "${color_err}not ok %d - %s${color_end}\n" "$total" "$friendly_name"
            {
                printf "\n"
                @cat "$testresult" >&2
                printf "\n"
            } >&2
        fi
        @rm "$testresult" &>/dev/null
    done

    printf -- "# -----\n# All tests: %s, failed: %d, skipped: %d\n" "${#all_tests[@]}" "$error" "$(( ${#all_tests[@]} - total ))">&2
    [[ "$error" == 0 ]] && [[ "${#all_tests[@]}" -eq "$total" ]]
}

function bach-on-exit() {
    if [[ "$?" -eq 0 ]]; then
        [[ "${BACH_DISABLED:-false}" == true ]] || bach-run-tests
    else
        printf "Bail out! %s\n" "Couldn't initlize tests."
    fi
}

trap bach-on-exit EXIT

function @mock-command() {
    @debug "@mock 'command'" "$@"
    function command() {
        command_not_found_handle command "$@"
    }
}
export -f @mock-command

function xargs() {
    declare param
    declare -a xargs_opts
    while param="${1:-}"; [[ -n "$param" ]]; do
        shift || true
        if [[ "$param" == "--" ]]; then
            xargs_opts+=("${BASH:-bash}" "-c" "$* \$@" "-s")
            break
        else
            xargs_opts+=("$param")
        fi
    done
    @debug "@mock-xargs" "${xargs_opts[@]}"
    if [[ "$#" -gt 0 ]]; then
        @xargs "${xargs_opts[@]}"
    else
        @dryrun xargs "${xargs_opts[@]}"
    fi
}
export -f xargs

function @generate_mock_function_name() {
    declare name="$1"
    @echo "mock_exec_${name}_$(@dryrun "${@}" | @md5sum | @cut -b1-32)"

}
export -f @generate_mock_function_name

function @mock() {
    declare -a param name cmd func body desttype
    name="$1"
    if [[ "$name" == @(builtin|declare|eval|printf) ]]; then
        @die "Cannot mock the builtin command: $name"
    fi
    desttype="$(@type -t "$name" )"
    if [[ "$desttype" == builtin ]] && [[ "$(@type -t "@mock-$name" )" == function ]]; then
        "@mock-$name" "${@:2}"
    fi
    while param="${1:-}"; [[ -n "$param" ]]; do
        shift
        [[ "$param" == '===' ]] && break
        cmd+=("$param")
    done
    if [[ "$name" == /* ]]; then
        @die "Cannot mock an absolute path: $name"
    elif [[ "$name" == */* ]] && [[ -e "$name" ]]; then
        @die "Cannot mock an existed path: $name"
    fi
    @debug "@mock $name"
    if [[ "$#" -gt 0 ]]; then
        @debug "@mock $name $*"
        func="$*"
    elif [[ ! -t 0 ]]; then
        @debug "@mock $name @cat"
        func="$(@cat)"
    else
        @debug "@mock $name $_echo"
        func="@dryrun \"${name}\" \"\$@\""
    fi
    if [[ "$name" == */* ]]; then
        [[ -d "${name%/*}" ]] || @mkdir -p "${name%/*}"
        @cat > "$name" <<SCRIPT
#!${BASH:-/bin/bash}
${func}
SCRIPT
        @chmod +x "$name" >&2
    else
        declare mockfunc
        if [[ "$desttype" == builtin && "${#cmd[@]}" -eq 1 ]]; then
            mockfunc="$name"
        else
            mockfunc="$(@generate_mock_function_name "${cmd[@]}")"
        fi
        if [[ -z "$desttype" ]]; then
            eval "function ${name}() {
                      declare mockfunc=\"\$(@generate_mock_function_name ${name} \"\${@}\")\"
                      if [[ \"\$(@type -t \"\$mockfunc\")\" == function ]]; then
                           \"\${mockfunc}\" \"\$@\"
                      else
                           @dryrun ${name} \"\$@\"
                      fi
                  }; export -f ${name}"
        fi
        #stderr name="$name"
        #body="function ${mockfunc}() { @debug Running mock : '${cmd[*]}' :; $func; }"
        declare mockfunc_seq="${mockfunc//@/__}_SEQ"
        mockfunc_seq="${mockfunc_seq//-/__}"
        body="function ${mockfunc}() {
            declare -gxi ${mockfunc_seq}=\"\${${mockfunc_seq}:-0}\";
            if [[ \"\$(@type -t \"${mockfunc}_\$(( ${mockfunc_seq} + 1))\")\" == function ]]; then
                let ${mockfunc_seq}++;
            fi;
            \"${mockfunc}_\${${mockfunc_seq}}\" \"\$@\";
        }; export -f ${mockfunc}"
        @debug "$body"
        eval "$body"
        for (( mockfunc__SEQ=1; mockfunc__SEQ <= ${BACH_MOCK_FUNCTION_MAX_COUNT:-0}; mockfunc__SEQ++ )); do
            [[ "$(@type -t "${mockfunc}_${mockfunc__SEQ}")" == function ]] || break
        done
        body="${mockfunc}_${mockfunc__SEQ}() {
            # @mock ${name} ${cmd[@]} ===
            $func
        }; export -f ${mockfunc}_${mockfunc__SEQ}"
        @debug "$body"
        eval "$body"
    fi
}
export -f @mock

function @@mock() {
    BACH_MOCK_FUNCTION_MAX_COUNT=15 @mock "$@"
}
export -f @@mock

function @mocktrue() {
    @mock "$@" === @true
}
export -f @mocktrue

function @mockfalse() {
    @mock "$@" === @false
}
export -f @mockfalse

function @mockall() {
    declare name body
    for name; do
        body="function ${name}() { @echo \"$name\" \"\$@\"; }; export -f \"$name\";"
        @debug "Mock $name: $body"
        eval "$body"
    done
}
export -f @mockall


BACH_FRAMEWORK__SETUP_FUNCNAME="_bach_framework_setup_"
alias @setup="function $BACH_FRAMEWORK__SETUP_FUNCNAME"

BACH_FRAMEWORK__PRE_TEST_FUNCNAME='_bach_framework_pre_test_'
alias @setup-test="function $BACH_FRAMEWORK__PRE_TEST_FUNCNAME"

BACH_FRAMEWORK__PRE_ASSERT_FUNCNAME='_bach_framework_pre_assert_'
alias @setup-assert="function $BACH_FRAMEWORK__PRE_ASSERT_FUNCNAME"

function _bach_framework__run_function() {
    declare name="$1"
    if [[ "$(@type -t "$name")" == function ]]; then
        "$name"
    fi
}
export -f _bach_framework__run_function

function @dryrun() {
    printf '%s' "$1"
    [[ "$#" -gt 1 ]] && printf '  %s' "${@:2}"
    printf '\n'
}
export -f @dryrun

declare -gxa BACH_ASSERT_DIFF_OPTS=(-u)
declare -gx BACH_ASSERT_IGNORE_COMMENT="${BACH_ASSERT_IGNORE_COMMENT:-true}"
declare -gx BACH_ASSERT_DIFF="${BACH_ASSERT_DIFF:-diff}"

function assert-execution() (
    declare bach_test_name="$1" bach_tmpdir
    bach_tmpdir="$(@mktemp -d)"
    #trap '/bin/rm -vrf "$bach_tmpdir"' RETURN
    @pushd "${bach_tmpdir}" &>/dev/null
    @mkdir actual expected
    declare retval=1

    function command_not_found_handle() {
        declare mockfunc bach_cmd_name="$1"
        mockfunc="$(@generate_mock_function_name "$@")"
        # @debug "mockid=$mockid" >&2
        if [[ "$(type -t "${mockfunc}")" == function ]]; then
            @debug "[CNFH-func]" "${mockfunc}" "$@"
            "${mockfunc}" "$@"
        elif [[ "${bach_cmd_name}" == @(cd|command|echo|eval|exec|false|popd|pushd|pwd|source|true|type) ]]; then
            @debug "[CNFH-builtin]" "$@"
            builtin "$@"
        else
            @debug "[CNFH-default]" "$@"
            @dryrun "$@"
        fi
    } #8>/dev/null
    export -f command_not_found_handle
    export PATH=path-not-exists

    if @real "${BACH_ASSERT_DIFF}" "${BACH_ASSERT_DIFF_OPTS[@]}" <(
            @trap - EXIT
            set +euo pipefail
            (
                _bach_framework__run_function "$BACH_FRAMEWORK__SETUP_FUNCNAME"
                _bach_framework__run_function "$BACH_FRAMEWORK__PRE_TEST_FUNCNAME"
                "${bach_test_name}"
            )
            @echo "Exit code: $?"
        ) <(
            @trap - EXIT
            unset -f @mock @mockall @ignore @setup-test
            set +euo pipefail
            (
                _bach_framework__run_function "$BACH_FRAMEWORK__SETUP_FUNCNAME"
                _bach_framework__run_function "$BACH_FRAMEWORK__PRE_ASSERT_FUNCNAME"
                "${bach_test_name}"-assert
            )
            @echo "Exit code: $?"
        )
    then
        retval=0
    fi
    if [[ "$(@type -t "${bach_test_name}-assert")" != function ]]; then
        : @cat >&2 <<-EOF
# Could not find the assertion function for $bach_test_name
function ${bach_test_name}-assert() {

}

EOF
    fi
    @popd &>/dev/null
    @rm -rf "$bach_tmpdir"
    return "$retval"
)

function @comment() {
    @out "##BACH:" "$@"
}
export -f @comment

function @ignore() {
    declare bach_test_name="$1"
    eval "function $bach_test_name() { : ignore command '$bach_test_name'; }"
}
export -f @ignore

function @stderr() {
    printf "%s\n" "$@" >&2
}
export -f @stderr

function @stdout() {
    printf "%s\n" "$@"
}
export -f @stdout

function @load_function() {
    local file="${1:?script filename}"
    local func="${2:?function name}"
    @source <(@sed -Ene "/^function\s+${func}\\b/,/^}\$/p" "$file")
} 8>/dev/null
export -f @load_function

function @run() {
    declare script="${1:?missing script name}"
    shift
    @source "$script" "$@"
}
export -f @run
