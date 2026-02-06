# UNITY BUILD AUTOMATION FOR ANDROID

This repo lets you automate unity android builds and upload it to google play games' internal file sharing and optionally send a message to discord via a webhook.
This repo is tested to work in Fedora Linux (should work fine in any distro) and MacOS

## How To Setup

1. First clone the Repo

2. Run `bundle install` in the cloned directory to setup fastlane

3. Run `bash StartBuild.sh` once to intialize the config file which will create a build_config.env file

4. Populate the build_config files with the necessary info

   * **UNITY_PATH** refers to your editor executable path. MacOs might require you to append "Unity.app/Content/MacOS/Unity" ie it will be something like this
  
    > /Applications/Unity/Hub/Editor/<UNITY_VERSION>/Unity.app/Contents/MacOS/Unity

   * **REPO_URL** - I recomend using ssh and make sure you are authenticated to run git clone
  
   * **GP_SERVICE** - Refer the [Fastlane docs](https://docs.fastlane.tools/getting-started/android/setup/) , 'Collect Your credentials' section for info on how to get the gpservice.json file
  
   * **DISCORD_HOOK** can be obtained by going to your Discord Server Settings -> Integrations -> Webhooks and creating a new one
  
   * **PACKAGE_NAME** - your unity package name , same as the one from google play console
  
   * **BRANCH_NAME** - The name of the branch you want to poll for changes
     
5. Place this script in your projects Editor folder and set your Keystore file name, Keystore alias and Build profile path (optional)


```
public static class BuildScript
{
    public const string KEYSTORE_NAME = "user.keystore";
    public const string KEYSTORE_ALIAS = "Keystore alias name";
    public const string BUILD_PROFILE_PATH = string.Empty;
    
    public static void BuildAndroid() {
        // Set the build target to Android
        UnityEditor.EditorUserBuildSettings.SwitchActiveBuildTarget(UnityEditor.BuildTargetGroup.Android, UnityEditor.BuildTarget.Android);

        //read args passed from bash
        string[] args = System.Environment.GetCommandLineArgs();
        string keystorePass = "";
        string outputPath = "Builds/Android/MyGame.apk";//default path
        for (int i = 0; i < args.Length; i++) {
            if (args[i] == "-keystorePass" && i + 1 < args.Length) {
                keystorePass = args[i + 1];
            }
            
            if((args[i] == "-output" || args[i] == "-buildOutput")&& i + 1 < args.Length) {
                //where the apk will be saved
                outputPath = args[i + 1];
            }
        }
        SetBuildProfile();
        
        PlayerSettings.Android.useCustomKeystore = true;
        PlayerSettings.Android.keystoreName = KEYSTORE_NAME;
        PlayerSettings.Android.keystorePass = keystorePass;
        PlayerSettings.Android.keyaliasName = KEYSTORE_ALIAS;
        PlayerSettings.Android.keyaliasPass = keystorePass;
        
        
        UnityEditor.BuildPlayerOptions buildPlayerOptions = new UnityEditor.BuildPlayerOptions();
        buildPlayerOptions.scenes = EditorBuildSettings.scenes
            .Where(scene => scene.enabled)
            .Select(scene => scene.path)
            .ToArray();;
        buildPlayerOptions.target = UnityEditor.BuildTarget.Android;
        buildPlayerOptions.options = UnityEditor.BuildOptions.None;
        buildPlayerOptions.locationPathName = outputPath;
        Debug.Log("Building to path " + outputPath);
        // Build the apk
        UnityEditor.BuildPipeline.BuildPlayer(buildPlayerOptions);
    }

    //This only works in unity 6 or higher. even without this the build will work. 
    private static void SetBuildProfile() {
        
        if(string.IsNullOrEmpty( BUILD_PROFILE_PATH)) {
            Debug.LogWarning("No build profile path set");
            return;
        }


        var profile = AssetDatabase.LoadAssetAtPath<BuildProfile>(BUILD_PROFILE_PATH);
        if (profile != null) {
            BuildProfile.SetActiveBuildProfile(profile);
        }
    }
    
}
```
  
5. Test to see if the command works by running `bash StartBuild.sh --force`

 > By default it ignores initial commit upon a fress clone and already built commits . --force lets you bypass that

6. Now you can setup a cron job to check run `bash StartBuild.sh` in set intervals

The builds are stored in 'builds' folder within the repo and the apk's are named with the time and date of build
