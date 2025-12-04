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

git push --follow-tags
git push --tags
hub release create -m "v${tag}"$'\n'$'\n'"Version ${tag}" "$tag"

if hash mmark &>/dev/null; then
    find . -maxdepth 1 -type f -name 'README*.md' | while read readme; do
        readme="${readme##*/}"
        readme_lang="${readme#README}"
        readme_lang="${readme_lang%.md}"
        mmark -html -css //bach.sh/solarized-dark.min.css "$readme" | tee "index${readme_lang}.1.html"
        title="$(grep '<h1 ' "index${readme_lang}.1.html" | sed -e "s/<[^>]\+>//g" -e 's|/|\\/|g')"
        cat "index${readme_lang}.1.html" | sed "/<title>/s/>/>${title}/" | tee "index${readme_lang}.html" >/dev/null
        rm "index${readme_lang}.1.html"
    done
fi
