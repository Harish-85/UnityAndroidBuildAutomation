#!/bin/bash

set -e
exec 3>&1
exec 1>&2

echo "Starting Build Check"


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNITY_PATH="$2"
REPO_URL="$3"
BRANCH_NAME="$4"
KEYSTORE_PWD="$5"
PROJECT_PATH="$SCRIPT_DIR/ProjectFiles"
STATE_FILE="$SCRIPT_DIR/last_commit.txt"
OUTPUT_FILE="$1"
IGNORE_CHECK="$6"

PerformBuild(){
#for now assume build works
#SendDiscordMsg "Build Successful from commit $LATEST_COMMI_NAME \n $LATEST_COMMI_BODY"


"$UNITY_PATH" \
    -batchmode \
    -nographics \
    -quit\
    -projectPath "$PROJECT_PATH" \
    -executeMethod BuildScript.BuildAndroid\
    -keystorePass "$KEYSTORE_PWD" \
    -output "$OUTPUT_FILE"

BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
    #SendDiscordMsg "Build Successful from commit $LATEST_COMMI_NAME \n $LATEST_COMMI_BODY"
    echo "✅ Unity build succeeded! "
cat >&3 <<EOF
        LATEST_COMMIT_NAME=$(printf '%q' "$LATEST_COMMIT_NAME")
        LATEST_COMMIT_BODY=$(printf '%q' "$LATEST_COMMIT_BODY")
EOF

else
    echo "❌ Unity build failed with exit code $BUILD_EXIT"
    exit $BUILD_EXIT  # propagate failure if using CI/poll
fi

}

#building process here

if [ ! -d "ProjectFiles" ]; then
    mkdir "ProjectFiles"
fi

cd "$PROJECT_PATH"

if [ ! -d ".git" ]; then
    echo "No repo found cloning...."
    git clone $REPO_URL .
fi
echo "Fetching changes"
git fetch origin "$BRANCH_NAME"

LATEST_COMMIT=$(git rev-parse "origin/$BRANCH_NAME")
export LATEST_COMMIT_NAME=$(git log -n 1 origin/"$BRANCH_NAME" --pretty=format:%s)
export LATEST_COMMIT_BODY=$(git log -n 1 origin/"$BRANCH_NAME" --pretty=format:%b)

if [ ! -f "$STATE_FILE" ]; then
  echo "$LATEST_COMMIT" > "$STATE_FILE"
  if ! $IGNORE_CHECK; then
    echo "Initial commit recorded, skipping build"
    exit 0
  fi
fi

LAST_BUILT=$(cat "$STATE_FILE")
echo $LAST_BUILT
echo $LATEST_COMMIT

if [ "$LATEST_COMMIT" != "$LAST_BUILT" ] || $IGNORE_CHECK ; then
    echo "New commit detected $LATEST_COMMIT"
    git reset --hard "origin/$BRANCH_NAME"
    PerformBuild

    echo "$LATEST_COMMIT" > "$STATE_FILE"
	exit 0
else
    echo "Branch already uptodate . skipping build"
    exit 1;
fi
