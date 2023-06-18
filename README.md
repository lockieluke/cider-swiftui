# Cider for macOS - Next generation of Cider on macOS

This is not production-ready, only for internal use.

## Get the code ➡️

Clone Cider for macOS into `Cider-macOS` to avoid duplicate folder names

```shell
git clone https://github.com/ciderapp/project2-swiftui.git Cider-macOS
```

## Setting up the project 🧰

*<sub>Make sure you have [Xcode Command Line Tool](https://developer.apple.com/downloads/)(Xcode preferrably), [Rust Toolchain(Intel and ARM)](https://www.rust-lang.org/), [cargo-lipo](https://github.com/TimNN/cargo-lipo), [CMake](https://cmake.org/), [Task](https://taskfile.dev/), [Yarn **3**](https://yarnpkg.com/), [Node.js](https://nodejs.org/en/) installed</sub>*

Navigate into the project directory

```shell
cd Cider-macOS
```

**Task** will be used for executing tasks like managing dependencies and compiling, we recommend you to follow their [guide](https://taskfile.dev/installation/#setup-completions) on installing shell autocomplete

### Install build tools ⬇️

Install build dependencies with Homebrew

```shell
brew bundle
```

### Install JS Dependencies 📚

Yarn dependencies have to be installed before proceeding as Cider for macOS uses some TypeScript code for handling MusicKit Authorisation, Playback and the developer toolkit(`CiderDevUtils`) which includes the dev server

```shell
task install-deps:all-js
```

### Start Dev Server 🧭

The dev server handles all sorts of code compilation and it should be up at all times

```shell
task start:dev-server
```

<sub>Tip: Keep this open in a separate terminal tab</sub>

### Services and APIs ⚙️

You will need **GoogleService-Info.plist** in `Cider/` for it to work, this is mainly for Firebase and Google Analytics

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

If you are not sure about if you've installed all the required tools(dependency hell it really is), run this command.  Better yet, if you don't have `coke` installed correctly, it does it for you automatically.

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

## Credits ❤️

[cryptofyre](https://github.com/cryptofyre) CEO of Cider Collective

[lockieluke](https://github.com/lockieluke) Lead Developement of Cider for macOS

and GitHub contributors
