#!/bin/bash

set -e

#gcloud auth activate-service-account --key-file=gpservice.json
#export ACCESS_TOKEN=$(gcloud auth print-access-token)
LOCK_FILE="LockFile"
HandleLock(){
    if [ -f "$LOCK_FILE" ]; then
        OLD_PID=$(cat "$LOCK_FILE")

        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo "BUILD ALREADY RUNNING PID: $OLD_PID"
            exit 1
        else
            echo "STALE LOCK DETECTED . REMOVING..."
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

CleanupLock(){
    echo "REMOVING LOCK FILE"
    rm -f "$LOCK_FILE"
}

SendDiscordMsg(){
    local MESSAGE="$1"
    echo "SEnding message $1"
    curl -H "Content-Type: application/json" \
    -X POST \
    -d "$(jq -n --arg msg "$MESSAGE" '{content: $msg}')" \
    "$DISCORD_HOOK"
}

HandleConfigFile(){
    CONFIG_FILE="./build_config.env"

    # 1️⃣ Create default config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file not found. Creating default $CONFIG_FILE..."
cat > "$CONFIG_FILE" <<EOL
    # build_config.env - Edit these values
    UNITY_PATH=""
    REPO_URL=""
    DISCORD_HOOK=""
    PACKAGE_NAME=""
    KEYSTORE_PWD=""
    GP_SERVICE=""
EOL
        echo "Default config created. Please edit $CONFIG_FILE with valid paths."
        exit 1
    fi

    # 2️⃣ Load config
    source "$CONFIG_FILE"

    # 3️⃣ Validate config
    ERRORS=0

    if [ -z "$UNITY_PATH" ]; then
        echo "Error: UNITY_PATH is not set in $CONFIG_FILE"
        ERRORS=$((ERRORS+1))
    fi

    if [ -z "$REPO_URL" ]; then
        echo "Error: REPO_URL is not set in $CONFIG_FILE"
        ERRORS=$((ERRORS+1))
    fi

    if [ -z "$DISCORD_HOOK" ]; then
        echo "Error: DISCORD_HOOK is not set in $CONFIG_FILE"
        ERRORS=$((ERRORS+1))
    fi
    if [ -z "$PACKAGE_NAME" ]; then
        echo "Error: PACKAGE_NAME is not set in $CONFIG_FILE"
        ERRORS=$((ERRORS+1))
    fi
    if [ -z "$GP_SERVICE" ]; then
        echo "Error: GP_SERVICE is not set in $CONFIG_FILE"
        ERRORS=$((ERRORS+1))
    fi

    if [ "$ERRORS" -gt 0 ]; then
        echo "Please fix $CONFIG_FILE and re-run the script."
        exit 1
    fi
}



HandleLock
trap CleanupLock EXIT INT TERM
HandleConfigFile


echo "Using Unity at: $UNITY_PATH"
echo "Repo URL: $REPO_URL"
echo "Dicord URL: $DISCORD_HOOK"
echo "Keystore pwd: " $KEYSTORE_PWD
echo "GP_SERVICE path: " $GP_SERVICE
echo "PACKAGE_NAME : " $PACKAGE_NAME

BUILD_NAME="build_$(date +%b_%d_%Y_%I-%M-%S_%p).apk"
mkdir -p builds
echo "starting build"
OUTPUT=$(./BuildUnity.sh "$PWD/builds/$BUILD_NAME" "$UNITY_PATH" "$REPO_URL" "$KEYSTORE_PWD" 3>&1)
if [ $? -eq 0 ]; then
    eval "$OUTPUT"
    chmod a+x ./UploadBuild.sh
    buildInfo=$(./UploadBuild.sh "$PWD/builds/$BUILD_NAME" "$GP_SERVICE" "$PACKAGE_NAME")
    eval $buildInfo

    MSG="Build Successful from commit $LATEST_COMMIT_NAME
    COMMIT MSG : $LATEST_COMMIT_BODY
    BuildURL : [Download link]($IAS_URL)"

    SendDiscordMsg "$MSG"

    #copy the apk to backups
    cp

fi
