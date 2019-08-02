# Bach Testing Framework

## Bach

Bach is a unit testing frramework used for testing Bash scripts.

It's part of Shell Common Functions Library

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
        sudo rm -rf /  # This is the actual command to be running on your host!
    }
