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

if hash mmark &>/dev/null; then
    for readme in README*.md; do
        readme_lang="${readme#README}"
        readme_lang="${readme_lang%.md}"
        mmark -html -css //bach.sh/solarized-dark.min.css "$readme" | tee "index${readme_lang}.html"
        title="$(grep '<h1 ' "index${readme_lang}.html" | sed "s/<[^>]\+>//g")"
        sed -i "/<title>/s/>/>${title}/" "index${readme_lang}.html"
    done
fi
