#!/bin/sh

# Define required variables
REQUIRED_VARS="GITHUB_TOKEN RELEASE_VERSION"

printf "\n==== Check if required variables are set..."
for VAR in $REQUIRED_VARS; do
  eval VALUE=\$$VAR
  if [ -z "$VALUE" ]; then
    echo "Error: $VAR is not set. Please set the $VAR environment variable."
    exit 1
  fi
done
echo "OK"

printf "\n==== Set Environment Variables for Release Notes File ====\n"
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME="$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)"
fi

if [ -z "$RELEASE_NOTES_DIR" ]; then
  RELEASE_NOTES_DIR="_release-notes"
fi

# Create the directory if it does not exist
if [ ! -d "$RELEASE_NOTES_DIR" ]; then
  mkdir -p $RELEASE_NOTES_DIR
fi

if [ -z "$COMBINED_RELEASE_NOTES_FILE" ]; then
  COMBINED_RELEASE_NOTES_FILE="RELEASE_NOTES.md"
fi

if [ -z "$TARGET_BRANCH" ]; then
  TARGET_BRANCH="main"
fi

TMP_RELEASE_NOTE_FILE="${RELEASE_NOTES_DIR}/${RELEASE_VERSION}_TMP.md"
RELEASE_NOTE_FILE="${RELEASE_NOTES_DIR}/${RELEASE_VERSION}.md"

echo "PROJECT_NAME: $PROJECT_NAME"
echo "RELEASE_NOTES_DIR: $RELEASE_NOTES_DIR"
echo "COMBINED_RELEASE_NOTES_FILE: $COMBINED_RELEASE_NOTES_FILE"
echo "TARGET_BRANCH: $TARGET_BRANCH"
echo "TMP_RELEASE_NOTE_FILE: $TMP_RELEASE_NOTE_FILE"
echo "RELEASE_NOTE_FILE: $RELEASE_NOTE_FILE"

printf "\n==== Set up GitHub CLI Auth Token ====\n"
export GH_TOKEN=$GITHUB_TOKEN

printf "\n==== Get milestone number ====\n"
MILESTONE_NUMBER=$(gh api repos/$GITHUB_REPOSITORY/milestones --jq ".[] | select(.title==\"$RELEASE_VERSION\") | .number")
export MILESTONE_NUMBER

printf "\n==== Get closed issues for the milestone ====\n"
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

printf "\n==== Create individual release notes ====\n"
echo "## $RELEASE_VERSION $(date +%Y-%m-%d)" > $TMP_RELEASE_NOTE_FILE
echo "" >> $TMP_RELEASE_NOTE_FILE
if [ $(jq length issues.json) -eq 0 ]; then
  echo "- 해당 릴리즈와 관련된 정상 처리된 이슈가 없습니다." >> $TMP_RELEASE_NOTE_FILE
else
  jq -r '.[] | "- Issue #\(.number): \(.title)"' issues.json >> $TMP_RELEASE_NOTE_FILE
fi

printf "\n==== Add safe directory and check if inside Git work tree ====\n"
git config --global --add safe.directory $(pwd)
git rev-parse --is-inside-work-tree

printf "\n==== Commit and push release notes ====\n"
echo "pwd: $(pwd)"
ls -al

git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
git fetch origin $TARGET_BRANCH:$TARGET_BRANCH
git checkout $TARGET_BRANCH
mv $TMP_RELEASE_NOTE_FILE $RELEASE_NOTE_FILE
git add $RELEASE_NOTE_FILE
if [ "$(git diff --name-only --cached)" ]; then git commit -m "Add release notes for version $RELEASE_VERSION"; fi
git push origin $TARGET_BRANCH

printf "\n==== Create combined release notes ====\n"
echo "# '${PROJECT_NAME}' Release Notes" > $COMBINED_RELEASE_NOTES_FILE
echo "" >> $COMBINED_RELEASE_NOTES_FILE
find $RELEASE_NOTES_DIR -name "*.md" -print0 | \
      sort -zrV | \
      xargs -0 -I{} sh -c 'cat {}; echo ""' >> $COMBINED_RELEASE_NOTES_FILE
sed -i.bak -e :a -e '/^\n*$/{$d;N;};/\n$/ba' $COMBINED_RELEASE_NOTES_FILE
rm $COMBINED_RELEASE_NOTES_FILE.bak
