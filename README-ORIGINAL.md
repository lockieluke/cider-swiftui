# Cider for macOS - Next generation of Cider on macOS

This is not production-ready, only for internal use.

## Get the code ➡️

Clone Cider for macOS into `Cider-macOS` to avoid duplicate folder names

```shell
git clone https://github.com/ciderapp/project2-swiftui.git Cider-macOS
```

## Setting up the project 🧰

*<sub>Make sure you have [Xcode Command Line Tool](https://developer.apple.com/downloads/)(Xcode preferrably), [Rust Toolchain(Intel and ARM)](https://www.rust-lang.org/), [cargo-lipo](https://github.com/TimNN/cargo-lipo), [CMake](https://cmake.org/), [Task](https://taskfile.dev/) and [Bun](https://bun.sh/) installed</sub>*

Navigate into the project directory

```shell
cd Cider-macOS
```

**Task** will be used for executing tasks like managing dependencies and compiling, we recommend you to follow their [guide](https://taskfile.dev/installation/#setup-completions) on installing shell autocomplete

### (Summary Command - All the quick start stuff)

Before you run the quickstart command, you might have to open Xcode to have it refresh all the SPM packages

:warning: Dev Server is no longer needed as *User Script Sandboxing* has been disabled

```shell
task quickstart
```

<sub>Setup a `.env` file with `CIDER_GOOGLE_SERVICE_URL` and `CIDER_UPDATE_SERVICE_GOOGLE_SERVICE_URL` so the script can automatically fetch all the `GoogleService-Info, ask me on Discord if you are unsure, you should have these values if you're a Cider employee</sub>

### Services and APIs ⚙️

You will need **GoogleService-Info.plist** in `Cider/` and `CiderUpdateService/` for it to work, this is mainly for Firebase and Google Analytics

## Building Cider 🔨

### Select signing account

Xcode needs your developer account for signing the app before Cider can be run on your Mac

![Screenshot of Xcode](https://github.com/ciderapp/project2-swiftui/blob/master/assets/screenshots/1.png?raw=true)

Go into Cider's build settings in Xcode, search for `signing` and change **Development Team** to your name

<sub>Make sure you have already signed into Xcode, change **Development Team** to Cider's internal developer account if you're a member of the Cider Team</sub>

![Screenshot of Xcode build settings](https://github.com/ciderapp/project2-swiftui/blob/master/assets/screenshots/2.png?raw=true)

You should be good to go!

### Build using Xcode

Select **Cider**(`Cider - Release` for release builds) as the build target, make sure it's not **CiderPlaybackAgent**

![Screenshot of selecting build targets](https://github.com/ciderapp/project2-swiftui/blob/master/assets/screenshots/3.png?raw=true)

Hit the **Command+B** or Click **Product** -> **Build**, or `task build:xc` for command line

![Screenshot of Xcode's build menu item](https://github.com/ciderapp/project2-swiftui/blob/master/assets/screenshots/4.png?raw=true)

## Run Cider 🥳

### Run using Xcode(GUI)

Assuming you already have Xcode opened, just simply click on the **Play** button, or `task run:xc` for command line

![Screenshot of Xcode's play button](https://github.com/ciderapp/project2-swiftui/blob/master/assets/screenshots/5.png?raw=true)

Voila! Cider should now be live on your Mac, happy hacking 🥰

### Verifying build toolchain 🏗️

Make sure you have all the things required to build Cider

```shell
task verify:toolchain
```

### Taskfile Tasks 📔

Learn more about the Taskfile tasks you can use when working on Cider

```shell
task --list
```

## Final words 💬

Please open an issue if you happen to run into any problems when building or developing Cider

## Notes ✏️

- Use [SFSafeSymbols](https://github.com/SFSafeSymbols/SFSafeSymbols) for SF symbols

- Make use of [SwiftyUtils](https://github.com/tbaranes/SwiftyUtils) where possible

- Utilise [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) when dynamic JSON parsing is needed, use Decoder for parsing static JSON content if possible

## Credits ❤️

[cryptofyre](https://github.com/cryptofyre) CEO of Cider Collective

[lockieluke](https://github.com/lockieluke) Lead Developement of Cider for macOS

and GitHub contributors
