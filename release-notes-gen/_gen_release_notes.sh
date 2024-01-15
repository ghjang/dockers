#!/bin/sh

# Set up GitHub CLI
mkdir -p ~/.config/gh
echo "github.com:" > ~/.config/gh/hosts.yml
echo "  oauth_token: $GITHUB_TOKEN" >> ~/.config/gh/hosts.yml

# Get milestone number
MILESTONE_NUMBER=$(gh api repos/$GITHUB_REPOSITORY/milestones --jq ".[] | select(.title==\"$TAG_VERSION\") | .number")
export MILESTONE_NUMBER

# Get closed issues for the milestone
if [ -n "$MILESTONE_NUMBER" ]; then
  ISSUES=$(curl -H "Authorization: token $GITHUB_TOKEN" \
                -H "Accept: application/vnd.github.v3+json" \
                "https://api.github.com/repos/$GITHUB_REPOSITORY/issues?milestone=$MILESTONE_NUMBER&state=closed")
  echo "$ISSUES" > closed_issues.txt
  echo "ISSUES value:"
  cat closed_issues.txt
  if [ "$ISSUES" != "null" ] && [ "$ISSUES" != "[]" ] && [ "$ISSUES" != "[\n]" ] && [ "$ISSUES" != "[\n\n]" ]; then
    ALL_CLOSED_ISSUE_COUNT=$(jq length closed_issues.txt)
    echo "해당 릴리즈와 관련된 closed 상태의 모든 이슈가 $ALL_CLOSED_ISSUE_COUNT개 있습니다."
    echo $ISSUES | jq '[.[] | select(any(.labels[]; .name=="invalid" or .name=="duplicate" or .name=="wontfix") | not)]' > issues.json
    FILTERED_CLOSED_ISSUE_COUNT=$(jq length issues.json)
    echo "필터링된 closed 상태의 이슈가 $FILTERED_CLOSED_ISSUE_COUNT개 있습니다."
  else
    echo "해당 릴리즈와 관련된 이슈가 없습니다."
    echo "[]" > issues.json
  fi
else
  echo "해당 릴리즈와 관련된 마일스톤이 없습니다."
  echo "[]" > issues.json
fi

# Create individual release notes
echo "## $TAG_VERSION $(date +%Y-%m-%d)" > _release-notes/$TAG_VERSION.md
echo "" >> _release-notes/${TAG_VERSION}_TMP.md
if [ $(jq length issues.json) -eq 0 ]; then
  echo "- 해당 릴리즈와 관련된 정상 처리된 이슈가 없습니다." >> _release-notes/${TAG_VERSION}_TMP.md
else
  jq -r '.[] | "- Issue #\(.number): \(.title)"' issues.json >> _release-notes/${TAG_VERSION}_TMP.md
fi

# Add safe directory and check if inside Git work tree
git config --global --add safe.directory $(pwd)
git rev-parse --is-inside-work-tree

# Commit and push release notes
echo "pwd: $(pwd)"
ls -al

git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
git fetch origin main:main
git checkout main
mv _release-notes/${TAG_VERSION}_TMP.md _release-notes/${TAG_VERSION}.md
git add _release-notes/${TAG_VERSION}.md
if [ "$(git diff --name-only --cached)" ]; then git commit -m "Add release notes for version $TAG_VERSION"; fi
git push origin main

# Create combined release notes
REPO_NAME=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
echo "# '${REPO_NAME}' Release Notes" > RELEASES_NOTES.md
echo "" >> RELEASES_NOTES.md
find _release-notes -name "*.md" -print0 | \
      sort -zrV | \
      xargs -0 -I{} sh -c 'cat {}; echo ""' >> RELEASES_NOTES.md
