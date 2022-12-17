# Cider for macOS - Next generation of Cider on macOS

This is not production-ready, only for internal use.

## Get the code

Clone Cider for macOS into `Cider-macOS` to avoid duplicate folder names

```shell
git clone https://github.com/ciderapp/project2-swiftui.git Cider-macOS
```

## Setting up the project

*<sub>Make sure you have [Xcode Command Line Tool](https://developer.apple.com/downloads/)(Xcode preferrably), [Task](https://taskfile.dev/), [Yarn](https://yarnpkg.com/), [Node.js](https://nodejs.org/en/), [Ruby](https://www.ruby-lang.org/en/), [Bundler](https://bundler.io/) and [CocoaPods](https://cocoapods.org/) installed</sub>*

Navigate into the project directory

```shell
cd Cider-macOS
```

**Task** will be used for executing tasks like managing dependencies and compiling, we recommend you to follow their [guide](https://taskfile.dev/installation/#setup-completions) on installing shell autocomplete

### Install JS Dependencies and compile TypeScript files

Cider for macOS uses some TypeScript for handling Authorisation and Playback, they are automatically compiled to JavaScript when Xcode builds the project.  However, before compiling anything, JS Dependencies would have to be installed

```shell
task install-js-deps
```

### Install CocoaPods plugins and dependencies

Cider for macOS uses CocoaPods for dependency management and some plugins are used for making the workflow easier

<sub>We don't like SPM, it's too unreliable</sub>

```shell
task install-pod-plugins
```

After all plugins have been installed, CocoaPods dependencies(Pods) can now be installed

```shell
pod install
```

### Select signing account

Xcode needs your developer account for signing the app before it can be run on your Mac and this has to be done before you can build Cider

![Screenshot of Xcode](https://github.com/ciderapp/project2-swiftui/blob/master/assets/screenshots/1.png?raw=true)

You have to first open the project with Xcode

```shell
pod open
```

<sub>This command can also be used for opening the `.xcworkspace` project during development</sub>

Go into Cider's build settings in Xcode, search for `signing` and change **Development Team** to your name

Make sure you have already signed into Xcode, change **Development Team** to Cider's internal developer account if you're a member of the Cider Team

![Screenshot of Xcode build settings](https://github.com/ciderapp/project2-swiftui/blob/master/assets/screenshots/2.png?raw=true)

You should be good to go!

## Build Cider!

There are two ways for building Cider

### Build using Command Line

Run the Taskfile command

```shell
task build-xc
```

Clean the build folder if you need to

```shell
task clean-xc
```

### Build using Xcode(GUI)

Open the `.xcworkspace` project if you haven't already

```shell
pod open
```

Hit the **Command+B** or Click **Product** -> **Build**

![Screenshot of Xcode's build menu item](https://github.com/ciderapp/project2-swiftui/blob/master/assets/screenshots/3.png?raw=true)

## Run Cider 🥳

Once Xcode/Command Line has finished building Cider, you can now run Cider on your Mac!

### Run using Command Line

Run the Taskfile command

```shell
task run-xc
```

### Run using Xcode(GUI)

Assuming you already have Xcode opened, just simply click on the **Play** button

![Screenshot of Xcode's play button](https://github.com/ciderapp/project2-swiftui/blob/master/assets/screenshots/4.png?raw=true)

Voila! Cider should now be live on your Mac, happy hacking 🥰

## Final words

Please do not hesitate to open an issue if you face any problems when building or developing Cider, we truly want everyone to be able to contribute to Cider and make Cider truly perfect!

## Credits

[cryptofyre](https://github.com/cryptofyre) CEO of Cider Collective

[lockieluke](https://github.com/lockieluke) Lead Developement of Cider for macOS

and all contributors that have helped us on GitHub
