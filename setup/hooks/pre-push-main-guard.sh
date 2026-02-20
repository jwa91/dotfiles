#!/usr/bin/env bash
# Blocks pushes to main unless HEAD has a version tag
# and CHANGELOG.md contains a matching entry.

remote="$1"
url="$2"

while read -r local_ref local_sha remote_ref remote_sha; do
    if [[ "$remote_ref" == "refs/heads/main" ]]; then
        tag=$(git tag --points-at "$local_sha" 2>/dev/null | grep "^v" | head -1)

        if [[ -z "$tag" ]]; then
            echo "✗ Push to main blocked: HEAD ($local_sha) has no version tag."
            echo "  Run: git tag vX.Y.Z"
            exit 1
        fi

        if ! grep -q "## \[${tag#v}\]" CHANGELOG.md; then
            echo "✗ Push to main blocked: CHANGELOG.md has no entry for $tag."
            echo "  Add a \"## [${tag#v}] - $(date +%Y-%m-%d)\" section."
            exit 1
        fi

        echo "✓ Push to main: $tag with changelog entry"
    fi
done
