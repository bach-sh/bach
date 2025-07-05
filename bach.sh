# -*- mode: sh -*-
# Bach Unit Testing Framework, https://bach.sh
# Copyright (C) 2019  Chai Feng <chaifeng@chaifeng.com>
#
# Bach Unit Testing Framework is dual licensed under:
# - GNU General Public License v3.0
# - Mozilla Public License 2.0
set -euo pipefail
IFS='.' read -r __major __minor _ <<< "${BASH_VERSION:-0.0.0}"
if [ "$__major" -lt 4 ] || { [ "$__major" -eq 4 ] && [ "$__minor" -lt 3 ]; }; then
    echo "Error: Bach Unit Testing Framework requires Bash version 4.3 or higher. Your current version is ${BASH_VERSION:-unknown}." >&2
    exit 1
fi
if [ -z "${BASH_VERSION:-}" ] || [ -z "${BASH_SOURCE:-}" ]; then
  echo "Error: Bach Unit Testing Framework must be run in Bash. Please switch to Bash and try again."
  exit 1
fi
shopt -s expand_aliases

builtin export BACH_COLOR="${BACH_COLOR:-auto}"
builtin export PS4='+(${BASH_SOURCE##*/}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

BACH_OS_NAME="$(uname)"
declare -gxr BACH_OS_NAME

declare -gxa bach_origin_paths=()
while builtin read -r -d: folder; do
    bach_origin_paths+=("$folder")
done <<< "${PATH}:"

function @out() {
    if [[ "${1:-}" == "-" || ! -t 0 ]]; then
        [[ "${1:-}" == "-" ]] && shift
        while IFS=$'\n' read -r line; do
            builtin printf "%s\n" "${*}$line"
        done
    elif [[ "$#" -gt 0 ]]; then
        builtin printf "%s\n" "$*"
    else
        builtin printf "\n"
    fi
} 8>/dev/null
builtin export -f @out

function @err() {
    @out "$@"
} >&2
builtin export -f @err

function @die() {
    @out "$@"
    exit 1
} >&2
builtin export -f @die

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
        builtin printf '[DEBUG] %s\n' "$*"
    } >&8
fi
builtin export -f @debug

function .bach.real-path() {
    declare folder name="$1"
    declare altname="${name#*|}"
    name="${name%|*}"
    for folder in "${bach_origin_paths[@]}"; do
        if [[ -x "$folder/$name" ]]; then
           builtin echo "$folder/$name"
           return 0
        elif [[ "$name" != "$altname" && -x "$folder/$altname" ]]; then
            builtin echo "$folder/$altname"
            return 0
        fi
    done
    return 1
}
builtin export -f .bach.real-path

builtin export BACH_DEV_STDIN=""

function .bach.restore-stdin() {
    if [[ ! -t 0 ]]; then
        declare name
        [[ -n "$BACH_DEV_STDIN" ]] || for name in /dev/ptmx /dev/pts/ptmx /dev/ttyv[0-9a-f]; do
            if [[ -r "$name" && -c "$name" ]]; then
                ls -l "$name" >&2
                BACH_DEV_STDIN="$name"
                break
            fi
        done
        exec 0<&-
        exec 0<"$BACH_DEV_STDIN"
    fi
}

function .bach.initialize(){
    enable -n alias bg bind dirs disown fc fg hash help history jobs kill suspend times ulimit umask unalias wait

    declare util name util_path

    declare -a bash_builtin_cmds=(cd enable popd pushd pwd shopt test trap type)

    for name in . command echo exec export false set true unset "${bash_builtin_cmds[@]}"; do
        eval "function @${name}() { builtin $name \"\$@\"; } 8>/dev/null; builtin export -f @${name}"
    done

    for name in eval; do
        eval "function @${name}() { builtin $name \"\$@\"; }; builtin export -f @${name}"
    done

    function @source() {
        declare script="$1"
        shift
        builtin source "$script" "$@"
    }

    declare -a bach_core_utils=(cat chmod cut diff find env grep ls "shasum|sha1sum" mkdir mktemp rm rmdir sed sort tee touch which xargs)

    for util in "${bach_core_utils[@]}"; do
        if [[ "$util" == "shasum|"* && "$BACH_OS_NAME" == FreeBSD ]]; then
            util="shasum|sha1"
        fi
        name="${util%|*}"
        util_path="$(.bach.real-path "$util")"
        eval "[[ -n \"${util_path}\" ]] || @die \"Fatal, CAN NOT find '$name' in \\\$PATH\"; function @${name}() { \"${util_path}\" \"\$@\"; } 8>/dev/null; builtin export -f @${name}"
    done

    .bach.restore-stdin
    @mockall "${bash_builtin_cmds[@]}" source .
    function export() { builtin export "$@"; @dryrun export "$@"; }

    eval "$(builtin declare -x | @real cut -d= -f1 | while read -rs name; do
        [[ "$name" = "declare -"* ]] || continue
        name="${name%%=*}"
        name="${name##* }"
        [[ "${name^^}" != BACH_* ]] || continue
        builtin echo "unset '$name' || builtin true"
    done)"
    builtin export LANG=C TERM=vt100
    unset name util_path
}

function @real() {
    declare name="$1" real_cmd
    if [[ "$name" == */* ||"$name" == @(bg|fc|fg|jobs|ulimit|umask|wait)  ]]; then
        @echo "$@"
        return
    fi
    declare -a cmd
    if [[ "$name" == @(alias|builtin|cd|command|declare|eval|false|getopts|hash|printf|read|set|type|unalias|unset) ]]; then
        cmd=(builtin "$name")
        [[ "$name" != declare ]] || cmd+=(-g)
    else
        real_cmd="$(.bach.real-path "$1" 7>&1 || true)"
        if [[ -z "${real_cmd}" ]]; then
            real_cmd="${name}_not_found"
        fi
        cmd=("${real_cmd}")
    fi
    cmd+=("${@:2}")
    @debug "[REAL-CMD]" "${cmd[@]}"
    "${cmd[@]}"
}
builtin export -f @real

function .bach.get-all-functions() {
    declare -F
}
builtin export -f .bach.get-all-functions

function .bach.skip-the-test() {
    declare test="$1" test_filter
    while read -d, test_filter; do
        [[ -n "$test_filter" ]] || continue
        [[ "$test" == $test_filter ]] && return 0
        [[ "$test" == test-$test_filter ]] && return 0
    done <<< "${BACH_TESTS:-},"
}
builtin export -f .bach.skip-the-test

function .bach.run-tests--get-all-tests() {
    .bach.get-all-functions | @sort -R | while read -r _ _ name; do
        [[ "$name" == test?* ]] || continue
        [[ "$name" == *-assert ]] && continue
        .bach.skip-the-test "$name" || continue
        builtin printf "%s\n" "$name"
    done
}

for donotpanic in donotpanic dontpanic do-not-panic dont-panic do_not_panic dont_panic; do
    eval "function @${donotpanic}() { builtin printf '\n%s\n  line number: %s\n  script stack: %s\n\n' 'DO NOT PANIC!' \"\${BASH_LINENO}\" \"\${BASH_SOURCE[*]}\"; builtin exit 1; } >&2; builtin export -f @${donotpanic};"
done

function .bach.is-function() {
    [[ "$(@type -t "$1")" == function ]]
}
builtin export -f .bach.is-function

declare -gr __bach_run_test__ignore_prefix="## BACH:"
function @comment() {
    @out "${__bach_run_test__ignore_prefix}" "$@"
}
builtin export -f @comment

function .bach.run-tests() {
    set -euo pipefail

    .bach.initialize

    for donotpanic in donotpanic dontpanic do-not-panic dont-panic do_not_panic dont_panic; do
        eval "function @${donotpanic}() { builtin true; }; builtin export -f @${donotpanic}"
    done

    function command() {
        if [[ "$1" != -* ]] && .bach.is-function "$1"; then
            "$@"
        else
            declare mockfunc="$(.bach.gen_function_name command "$@")"
            if .bach.is-function "${mockfunc}"; then
                @debug "[BC-func]" "${mockfunc}" "$@"
                "${mockfunc}" "$@"
            else
                command_not_found_handle command "$@"
            fi
        fi
    }
    builtin export -f command

    function xargs() {
        declare param
        declare -a xargs_opts
        while param="${1:-}"; [[ -n "${param:-}" ]]; do
            shift || true
            if [[ "$param" == "--" ]]; then
                xargs_opts+=("${BASH:-bash}" "-c" "$(builtin printf "'%s' " "$@") \$@" "-s")
                break
            else
                xargs_opts+=("$param")
            fi
        done
        @debug "@mock-xargs" "${xargs_opts[@]}"
        if [[ "$#" -gt 0 ]]; then
            @xargs "${xargs_opts[@]}"
        else
            [[ -t 0 ]] || @cat &>/dev/null
            @dryrun xargs "${xargs_opts[@]}"
        fi
    }
    builtin export -f xargs

    function [() {
        declare mockfunc;
        local _mock_regex
        [[ -z "${_bach_mock_regex_test-}" ]] || for _mock_regex in "${_bach_mock_regex_test[@]}"; do
            if [[ "$*" =~ $_mock_regex ]]; then
                mockfunc="$(.bach.gen_function_name "[" "$_mock_regex")";
                break;
            fi
        done
        [[ -n "${mockfunc-}" ]] || mockfunc="$(.bach.gen_function_name "[" "$@")";
        if .bach.is-function "${mockfunc}"; then
            @debug "[LSB-func]" "${mockfunc}" "$@"
            "${mockfunc}" "$@"
        else
            builtin '[' "$@"
        fi
    }
    builtin export -f '['

    function echo() {
        declare mockfunc;
        local _mock_regex
        [[ -z "${_bach_mock_regex_echo-}" ]] || for _mock_regex in "${_bach_mock_regex_echo[@]}"; do
            if [[ "$*" =~ $_mock_regex ]]; then
                mockfunc="$(.bach.gen_function_name echo "$_mock_regex")";
                break;
            fi
        done
        [[ -n "${mockfunc-}" ]] || mockfunc="$(.bach.gen_function_name echo "$@")";
        if .bach.is-function "${mockfunc}"; then
            @debug "[LSB-func]" "${mockfunc}" "$@"
            "${mockfunc}" "$@"
        else
            builtin echo "$@"
        fi
    }
    builtin export -f echo

    if [[ "${BACH_ASSERT_IGNORE_COMMENT}" == true ]]; then
        BACH_ASSERT_DIFF_OPTS+=(-I "^${__bach_run_test__ignore_prefix}")
    fi

    declare color_ok color_err color_warn color_end
    if [[ "$BACH_COLOR" == "always" ]] || [[ "$BACH_COLOR" != "no" && -t 1 && -t 2 ]]; then
        color_ok="\e[1;32m"
        color_err="\e[1;31m"
        color_warn="\e[1;33m"
        color_end="\e[0;m"
    else
        color_ok=""
        color_err=""
        color_warn=""
        color_end=""
    fi
    declare name friendly_name testresult test_name_assert_fail
    declare -i total=0 error=0
    declare -a all_tests
    mapfile -t all_tests < <(.bach.run-tests--get-all-tests)
    @echo "1..${#all_tests[@]}"
    for name in "${all_tests[@]}"; do
        # @debug "Running test: $name"
        friendly_name="${name/#test-/}"
        friendly_name="${friendly_name//-/ }"
        friendly_name="${friendly_name//  / -}"
        : $(( ++total ))
        testresult="$(@mktemp)"
        @set +e
        .bach.assert-execution "$name" &>"$testresult"; test_retval="$?"
        @set -e
        if [[ "$name" == test-ASSERT-FAIL-* ]]; then
            test_retval="$(( test_retval == 0?1:0 ))"
            test_name_assert_fail="${color_err}ASSERT FAIL${color_end}"
            friendly_name="${friendly_name/#ASSERT FAIL/}"
        else
            test_name_assert_fail=""
        fi
        if [[ "$test_retval" -eq 0 ]]; then
            builtin printf "${color_ok}ok %d - ${test_name_assert_fail}${color_ok}%s${color_end}\n" "$total" "$friendly_name"
        else
            : $(( ++error ))
            builtin printf "${color_err}not ok %d - ${test_name_assert_fail}${color_err}%s${color_end}\n" "$total" "$friendly_name"
            {
                builtin printf "\n"
                @cat "$testresult" >&2
                builtin printf "\n"
            } >&2
        fi
        declare _allow_real="$(@grep "^# \\[ALLOW-REAL\\]" -- "$testresult")" || true
        [[ -z "${_allow_real-}" ]] || builtin printf "${color_warn}%s${color_end}\n" "${_allow_real}" >&2
        @rm "$testresult" &>/dev/null
    done

    declare color_result="$color_ok"
    if (( error > 0 )); then
        color_result="$color_err"
    fi
    builtin printf -- "# -----\n#${color_result} All tests: %s, failed: %d, skipped: %d${color_end}\n" \
           "${#all_tests[@]}" "$error" "$(( ${#all_tests[@]} - total ))">&2
    [[ "$error" == 0 ]] && [[ "${#all_tests[@]}" -eq "$total" ]]
}

function .bach.on-exit() {
    if [[ -o xtrace ]]; then
        exec 8>&2
        BASH_XTRACEFD=8
    fi
    if [[ "$?" -eq 0 ]]; then
        [[ "${BACH_DISABLED:-false}" == true ]] || .bach.run-tests
    else
        builtin printf "Bail out! %s\n" "Couldn't initlize tests."
    fi
}

trap .bach.on-exit EXIT

function .bach.gen_function_name() {
    declare name="$1"
    @echo "mock_exec_${name}_$(@dryrun "${@}" | @shasum | @cut -b1-7)"
}
builtin export -f .bach.gen_function_name

function @mock() {
    declare -a param name cmd func body desttype
    name="$1"
    if [[ "$name" == @(builtin|declare|export|eval|set|unset|true|false|read) ]]; then
        @die "Cannot mock the builtin command: $name"
    fi
    if [[ command == "$name" && "$2" != -* ]]; then
        shift
        name="$1"
    fi
    desttype="$(@type -t "$name" || true)"
    for param; do
        if [[ "$param" == '===' ]]; then
            shift
            break
        fi
        cmd+=("$param")
    done
    shift "${#cmd[@]}"
    if [[ "$name" == /* ]]; then
        @die "Cannot mock an absolute path: $name"
    elif [[ "$name" == */* ]] && [[ -e "$name" ]]; then
        @die "Cannot mock an existed path: $name"
    fi
    @debug "@mock $name"
    if [[ "$#" -gt 0 ]]; then
        @debug "@mock $name $*"
        declare -a params=("$@")
        func="$(declare -p params); \"\${params[@]}\""
        #func="$*"
    elif [[ ! -t 0 ]]; then
        @debug "@mock $name @cat"
        func="$(@cat)"
    fi
    if [[ -z "${func:-}" ]]; then
        @debug "@mock default $name"
        if [[ "$name" == echo ]]; then
            func="@dryrun ${name} \"\$@\" >&7"
        else
            func="if [[ -t 0 ]]; then @dryrun \"${name}\" \"\$@\" >&7; fi"
        fi
    elif [[ "$name" == echo ]]; then
        @die "Cannot mock the builtin command: $name"
    fi
    if [[ "$name" == */* ]]; then
        [[ -d "${name%/*}" ]] || @mkdir -p "${name%/*}"
        @cat > "$name" <<SCRIPT
#!${BASH:-/bin/bash}
${func}
SCRIPT
        @chmod +x "$name" >&2
    else
        if [[ -z "$desttype" || "$desttype" == builtin ]]; then
            eval "function ${name}() {
                      declare mockfunc;
                      local _mock_regex
                      [[ -z \"\${_bach_mock_regex_${name//[^a-zA-Z_]/__}-}\" ]] || for _mock_regex in \"\${_bach_mock_regex_${name//[^a-zA-Z_]/__}[@]}\"; do
                          if [[ \"\$*\" =~ \$_mock_regex ]]; then
                              mockfunc=\"\$(.bach.gen_function_name ${name} \"\$_mock_regex\")\";
                              break;
                          fi
                      done
                      [[ -n \"\${mockfunc-}\" ]] || mockfunc=\"\$(.bach.gen_function_name ${name} \"\$@\")\";
                      if .bach.is-function \"\$mockfunc\"; then
                           \"\${mockfunc}\" \"\$@\"
                      else
                           @dryrun ${name} \"\$@\" >&7
                      fi
                  }; builtin export -f ${name}"
        fi
        declare mockfunc
        mockfunc="$(.bach.gen_function_name "${cmd[@]}")"
        #stderr name="$name"
        #body="function ${mockfunc}() { @debug Running mock : '${cmd[*]}' :; $func; }"
        declare mockfunc_seq="${mockfunc//_/__}_SEQ"
        mockfunc_seq="${mockfunc_seq//[-\!+.@\[\]\{\}~]/_}"
        body="function ${mockfunc}() {
            declare -gxi ${mockfunc_seq}=\"\${${mockfunc_seq}:-0}\";
            if .bach.is-function \"${mockfunc}_\$(( ${mockfunc_seq} + 1))\"; then
                let ++${mockfunc_seq};
            fi;
            \"${mockfunc}_\${${mockfunc_seq}}\" \"\$@\";
        }; builtin export -f ${mockfunc}"
        @debug "$body"
        eval "$body"
        for (( mockfunc__SEQ=1; mockfunc__SEQ <= ${BACH_MOCK_FUNCTION_MAX_COUNT:-0}; ++mockfunc__SEQ )); do
            .bach.is-function "${mockfunc}_${mockfunc__SEQ}" || break
        done
        body="function ${mockfunc}_${mockfunc__SEQ}() {
            # @mock ${name} ${cmd[@]} ===
            $func
        }; builtin export -f ${mockfunc}_${mockfunc__SEQ}"
        @debug "$body"
        eval "$body"
    fi
}
builtin export -f @mock

function @@mock() {
    BACH_MOCK_FUNCTION_MAX_COUNT=15 @mock "$@"
}
builtin export -f @@mock

function @mockpipe() {
    @mock "$@" === @cat
}
builtin export -f @mockpipe

function @mocktrue() {
    @mock "$@" === @true
}
builtin export -f @mocktrue

function @mockfalse() {
    @mock "$@" === @false
}
builtin export -f @mockfalse

function @mock-regex() {
    declare _param _name="${1:?missing command name}"
    if [[ "$_name" = "[" ]]; then _name=test; fi
    _name="${_name//[^a-zA-Z_]/__}"
    declare -a _mock_param=()
    for _param; do
        [[ "$_param" = "===" ]] && break
        _mock_param+=("$_param")
    done
    shift "${#_mock_param[@]}"
    eval "[[ -n \"\${_bach_mock_regex_${_name}-}\" ]] || declare -gax _bach_mock_regex_${_name}; _bach_mock_regex_${_name}+=(\"${_mock_param[*]:1}\")"
    @debug mock-regex: @mock "${_mock_param[0]}" "${_mock_param[*]:1}" "$@"
    @mock "${_mock_param[0]}" "${_mock_param[*]:1}" "$@"
}
builtin export -f @mock-regex

function @mockall() {
    declare name
    for name; do
        @mock "$name"
    done
}
builtin export -f @mockall

function @allow-real() {
    @echo "# [ALLOW-REAL]" "$@" >&2
    @mock "$@" === @real "$@"
}
builtin export -f @allow-real

function @capture() {
    @mock "$@" <<_EOS_207_
@assert-capture "$@"
_EOS_207_
}

function @assert-capture() {
    @echo "## Capture input: " "$@"
    @echo "$@" "<<_BACH_ASSERT_CAPTURE_"
    @cat
    @echo _BACH_ASSERT_CAPTURE_
}

BACH_FRAMEWORK__SETUP_FUNCNAME="_bach_framework_setup_"
alias @setup="function $BACH_FRAMEWORK__SETUP_FUNCNAME"

BACH_FRAMEWORK__PRE_TEST_FUNCNAME='_bach_framework_pre_test_'
alias @setup-test="function $BACH_FRAMEWORK__PRE_TEST_FUNCNAME"

BACH_FRAMEWORK__PRE_ASSERT_FUNCNAME='_bach_framework_pre_assert_'
alias @setup-assert="function $BACH_FRAMEWORK__PRE_ASSERT_FUNCNAME"

function .bach.run_function() {
    declare name="$1"
    if .bach.is-function "$name"; then
        "$name"
    fi
}
builtin export -f .bach.run_function

function @dryrun() {
    builtin declare param
    builtin declare -a input
    [[ "$#" -le 1 ]] || {
        for param in "${@:2}"; do
	    if [[ -z "$param" ]]; then input+=($'\x1b[31m\u2205\x1b[0m'); else input+=("$param"); fi
        done
        builtin printf -v param '  %s' "${input[@]}"
    }
    builtin echo "${1}${param:-}"
}
builtin export -f @dryrun

declare -gxa BACH_ASSERT_DIFF_OPTS=(-u)
declare -gx BACH_ASSERT_IGNORE_COMMENT="${BACH_ASSERT_IGNORE_COMMENT:-true}"
declare -gx BACH_ASSERT_DIFF="${BACH_ASSERT_DIFF:-diff}"

function .bach.assert-execution() (
    @unset BACH_TESTS
    declare bach_test_name="$1" bach_tmpdir bach_actual_output bach_expected_output
    bach_tmpdir="$(@mktemp -d)"
    #trap '/bin/rm -vrf "$bach_tmpdir"' RETURN
    @mkdir "${bach_tmpdir}/test_root"
    @pushd "${bach_tmpdir}/test_root" &>/dev/null
    declare retval=1

    exec 7>&2

    function command_not_found_handle() {
        declare mockfunc bach_cmd_name="$1"
        [[ -n "$bach_cmd_name" ]] || @out "Error: Bach found an empty command at line ${BASH_LINENO}." >&7
        mockfunc="$(.bach.gen_function_name "$@")"
        # @debug "mockid=$mockid" >&2
        if .bach.is-function "${mockfunc}"; then
            @debug "[CNFH-func]" "${mockfunc}" "$@"
            "${mockfunc}" "$@"
        elif [[ "${bach_cmd_name}" == @(cd|command|echo|eval|exec|false|popd|pushd|pwd|source|true|type) ]]; then
            @debug "[CNFH-builtin]" "$@"
            builtin "$@"
        else
            @debug "[CNFH-default]" "$@"
            @dryrun "$@"
        fi
    } >&7 #8>/dev/null
    builtin export -f command_not_found_handle

    function .bach.pre_run_test_and_assert() {
        @trap - EXIT RETURN
        @set +euo pipefail
        declare -gxr PATH=bach-fake-path
        .bach.restore-stdin
        .bach.run_function "$BACH_FRAMEWORK__SETUP_FUNCNAME"
    }
    function .bach.run_test() (
        .bach.pre_run_test_and_assert
        .bach.run_function "${BACH_FRAMEWORK__PRE_TEST_FUNCNAME}"
        "${1}"
    ) 7>&1

    function .bach.run_assert() (
        @unset -f @mock @mockall @ignore @setup-test
        .bach.pre_run_test_and_assert
        .bach.run_function "${BACH_FRAMEWORK__PRE_ASSERT_FUNCNAME}"
        "${1}-assert"
    ) 7>&1
    bach_actual_stdout="${bach_tmpdir}/actual-stdout.txt"
    bach_expected_stdout="${bach_tmpdir}/expected-stdout.txt"
    if .bach.is-function "${bach_test_name}-assert"; then
        @cat <(
            .bach.run_test "$bach_test_name"
            @echo "# Exit code: $?"
        ) > "${bach_actual_stdout}"
        @cat <(
            .bach.run_assert "$bach_test_name"
            @echo "# Exit code: $?"
        ) > "${bach_expected_stdout}"
        @cd ..
        if @real "${BACH_ASSERT_DIFF}" "${BACH_ASSERT_DIFF_OPTS[@]}" -- \
            "${bach_actual_stdout##*/}" "${bach_expected_stdout##*/}"
        then
            retval=0
        fi
    else
        .bach.run_test "$bach_test_name" |
            @tee /dev/stderr | if [[ "$bach_test_name" = test-ASSERT-FAIL-* ]]; then
                @cat
                @echo "${__bach_run_test__ignore_prefix} Should fail"
            else
                @grep "^${__bach_run_test__ignore_prefix} \\[assert-" >/dev/null
            fi
        retval="$?"
    fi
    @popd &>/dev/null
    @rm -rf "$bach_tmpdir"
    return "$retval"
)

function @ignore() {
    declare name
    for name; do
        if [[ "$name" == @(builtin|declare|eval|set|unset|true|false|read) ]]; then
            @die "Cannot ignore the builtin command: $name"
        elif [[ "$name" == export ]]; then
          function export() { builtin export "$@"; }
        else
          eval "function ${name}() {
              declare mockfunc=\"\$(.bach.gen_function_name ${name} \"\${@}\")\";
              if .bach.is-function \"\$mockfunc\"; then
                  \"\${mockfunc}\" \"\$@\";
              fi
          }; builtin export -f ${name}"
        fi
    done
}
builtin export -f @ignore

function @stderr() {
    builtin printf "%s\n" "$@" >&2
}
builtin export -f @stderr

function @stdout() {
    builtin printf "%s\n" "$@"
}
builtin export -f @stdout

function @load_function() {
    local file="${1:?script filename}"
    local func="${2:?function name}"
    @source <(@sed -Ene "/^function[[:space:]]+${func}([\(\{\[[:space:]]|[[:space:]]*\$)/,/^}\$/p" "$file")
} 8>/dev/null
builtin export -f @load_function

builtin export BACH_STARTUP_PWD="${PWD:-$(pwd)}"
function @run() {
    declare script="${1:?missing script name}"
    shift
    builtin pushd "${BACH_STARTUP_PWD}" &>/dev/null
    @source "$script" "$@"
    builtin popd &>/dev/null
}
builtin export -f @run

function @fail() {
    declare retval=1
    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        retval="$1"
        shift
    fi
    if [[ "$#" -gt 0 ]]; then
        @out "${@}"
    fi
    builtin exit "${retval}"
}
builtin export -f @fail

function @assert-equals() {
    declare expected="${1:?missing the expected result}" actual="${2:?missing the actual result}"

    if [[ "${expected}" == "${actual}" ]]; then
        @out <<EOF
${__bach_run_test__ignore_prefix} [assert-equals] expected: ${expected}
##                         actual: ${actual}
EOF
    else
        @die - 2>&7 <<EOF
Assert Failed:
     Expected: $expected
      But got: $actual
EOF
    fi
} >&7
builtin export -f @assert-equals

function @assert-fail() {
    declare expected="<non-zero>" actual="$?"
    [[ "$actual" -eq 0 ]] || expected="$actual"
    @assert-equals "$expected" "$actual"
}
builtin export -f @assert-fail

function @assert-success() {
    declare expected=0 actual="$?"
    @assert-equals "$expected" "$actual"
}
builtin export -f @assert-success

function @do-nothing() {
    :
}
builtin export -f @do-nothing

function @unmock() {
    declare name="${1:?missing command name}"
    declare mockfunc="$(.bach.gen_function_name "${@}")";
    if .bach.is-function "$mockfunc"; then
        unset -f "$mockfunc"
    fi
}
builtin export -f @unmock
