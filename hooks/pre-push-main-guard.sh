#!/usr/bin/env bash
# Blocks pushes from main unless HEAD has a version tag
# and CHANGELOG.md contains a matching entry.
#
# prek's pre-push stage does not forward stdin, args, or PRE_COMMIT_* env
# vars to language=script hooks, so this guard checks local state directly:
# current branch == main AND HEAD has a v* tag with matching changelog entry.
# Bypass with: SKIP=require-tag-and-changelog git push

branch=$(git symbolic-ref --short HEAD 2>/dev/null || true)
if [[ "$branch" != "main" ]]; then
    exit 0
fi

sha=$(git rev-parse HEAD)
tag=$(git tag --points-at "$sha" 2>/dev/null | grep "^v" | head -1)

if [[ -z "$tag" ]]; then
    echo "✗ Push to main blocked: HEAD ($sha) has no version tag."
    echo "  Run: git tag vX.Y.Z"
    echo "  Bypass: SKIP=require-tag-and-changelog git push"
    exit 1
fi

if ! grep -q "## \[${tag#v}\]" CHANGELOG.md; then
    echo "✗ Push to main blocked: CHANGELOG.md has no entry for $tag."
    echo "  Add a \"## [${tag#v}] - $(date +%Y-%m-%d)\" section."
    exit 1
fi

echo "✓ Push to main: $tag with changelog entry"
