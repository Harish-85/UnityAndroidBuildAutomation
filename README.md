This repo lets you automate unity android builds and upload it to google play games' internal file sharing and optionally send a message to discord via a webhook.
This repo is tested to work in Fedora Linux (should work fine in any distro) and MacOS

# How To Setup

1. First clone the Repo

2. Run `bundle install` in the cloned directory to setup fastlane

3. Run `bash StartBuild.sh` once to intialize the config file which will create a build_config.env file

4. Populate the build_config files with the necessary info

   * **UNITY_PATH** refers to your editor executable path. MacOs might require you to append "Unity.app/Content/MacOS/Unity" ie it will be something like this
  
    > /Applications/Unity/Hub/Editor/<UNITY_VERSION>/Unity.app/Contents/MacOS/Unity

   * **REPO_URL** - I recomend using ssh and make sure you are authenticated to run git clone
  
   * **GP_SERVICE** - Refer the [Fastlane docs' ](https://docs.fastlane.tools/getting-started/android/setup/) ,Collect Your credentials' section to get the gpservice.json file
  
   * **DISCORD_HOOK** can be obtained by going to your Discord Server Settings -> Integrations -> Webhooks and creating a new one
  
   * **PACKAGE_NAME** - your unity package name , same as the one from google play console
  
   * **BRANCH_NAME** - The name of the branch you want to poll for changes
  
5. Test to see if the command works by running `bash StartBuild.sh --force`

 > By default it ignores initial commit upon a fress clone and already built commits . --force lets you bypass that

6. Now you can setup a cron job to check run `bash StartBuild.sh` in set intervals

The builds are stored in 'builds' folder within the repo and the apk's are named with the time and date of build
