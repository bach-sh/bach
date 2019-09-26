#!/usr/bin/env bash
set -euo pipefail
tag="${1:?missing the tag, such as: 1.0}"

if [[ -z "$(git tag --list "$tag")" ]]; then
    echo "Couldn't find the tag '$tag'."
    exit 1
fi

if ! sed -Ene '/^## Versioning$/,+2p' README.md | grep -F "$tag"; then
    echo "Update readme to release version $tag"
    exit 1
fi

git push
git push --tags
hub release create -m "v${tag}"$'\n'$'\n'"Version ${tag}" "$tag"
