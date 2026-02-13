# Cider SwiftUI
<sub>Formerly Cider for macOS, codenamed `project2-swiftui`</sub>

> [!IMPORTANT] 
This project is no longer actively maintained nor functional. This serves as a technical endeavour showing how SwiftUI, Rust and TypeScript can work together in a native macOS App

[Original README](./README-ORIGINAL.md)

[Licence](./LICENSE)

[Code Review by Claude](./CLAUDE_REVIEW.md)

<img src="https://cdn.lockie.dev/cider-6.jpg" alt="Cider Hero">
<img src="https://cdn.lockie.dev/cider-4.jpg" alt="Cider Hero 2">

## Story

In August 2022, I joined [Cider Collective](https://cider.sh) *as a 15-year-old developer* to reengineer their then Electron-based Apple Music client in SwiftUI. From 2022–2024, I rebuilt their Apple Music client from the ground up before the era of agentic coding. The goal was simple: to develop a faster and more efficient version of Cider that could run on lower-end devices using native technologies like SwiftUI and Rust. This version of Cider integrated many services and APIs such as Firebase for authentication and Sentry for analytics. It was a full-stack solution with work done on the backend not seen in this repository.

## Architecture

This version of Cider provided significant performance advantages: it used 60% less memory and had marginally lower CPU usage even during playback. I have always been an advocate for making software with native technologies where possible and avoiding solutions like Electron at all costs, so I was naturally very passionate about the project and consistently contributed to it.

A multi-process architecture was developed for this version of Cider to ensure playback is never interrupted even if the main UI/main thread is locked up, which could happen with SwiftUI components in earlier versions of macOS. The multi-process architecture separates processes into the following parts:

- Main UI/Binary - Cider.app
- Playback Agent - as seen in [MKJSPlayback.swift](https://github.com/lockieluke/cider-swiftui/blob/f437d8a1f7769655049531824bcee7f0c39c62dd/Cider/Utils/MKJSPlayback.swift#L11), deals with playback in a separate WebKit process with JavaScript interop code in [CiderWebModules](./CiderWebModules)
- Cider Elevation Helper - used as a sandbox escape for publishing [Discord RPC](https://discord.com/developers/docs/topics/rpc) updates about the user's playback status

<img src="https://cdn.lockie.dev/cider-10.jpg" alt="Cider's performance metrics">

<img src="https://cdn.lockie.dev/cider-27.jpg" alt="Cider's packaging strategy">
    
Since the main binary has [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox) and [Hardened Runtime](https://developer.apple.com/documentation/security/hardened-runtime) enabled, it is unable to update the user's Discord playback status because historically Discord RPC's UNIX socket was located at `$HOME/Library/Application Support/Discord/discord-ipc-0` and that is outside Cider's sandbox environment. Cider Elevation Helper exists as an XPC helper escaping the sandbox and uses [discord-presence](https://lib.rs/crates/discord-presence) in Rust via an [FFI](https://en.wikipedia.org/wiki/Foreign_function_interface) built by [swift-bridge](https://github.com/chinedufn/swift-bridge). Honestly, I still do not know how Apple allowed this back then.

<img src="https://cdn.lockie.dev/cider-24.jpg" alt="Discord RPC">
    
Playback is handled by [MusicKitJS](https://developer.apple.com/musickit/web/) in a [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview). Actions are initiated from Swift via a JavaScript bridge (interop code) in [CiderWebModules](./CiderWebModules/src/injections/mkjs-playback). Information about playback such as the queue and the currently playing media is reported back to the main UI. In early versions, the WKWebView was hosted in a completely separate process but was later removed due to reliability issues. The DevTools panel can be decoupled from the main UI using private API calls.

<img src="https://cdn.lockie.dev/cider-28.jpg" alt="Playback">
    
[Video showing playback](https://cdn.lockie.dev/cider-playback-demo.webm)

## Performance

Due to the nature of the technologies used, the app uses far less memory than the Electron-based counterpart. However, because of the quirks in SwiftUI, an app built in Swift does not necessarily equal fast and efficient. A lot of time was spent optimising the code and making it launch as quickly as possible. Aggressive caching of user information and internal data using [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) helped massively in terms of startup times, but knowing when to invalidate the cached data is very important as well.

<img src="https://cdn.lockie.dev/cider-launch.gif" alt="Cider launching">
    
<img src="https://cdn.lockie.dev/cider-18.jpg" alt="Cider memory usage">
    
## Autoupdate
I developed an auto update system from scratch because I hated how complicated [Sparkle](https://sparkle-project.org/) was.  It checks for updates by fetching a release manifest from a Firebase endpoint and notifies the user if an update is ready to be downloaded.  The auto update system then downloads the update and spawns Cider Elevation Helper as a detached XPC service to replace the current application bundle with the new one from the temporary directory.

<img src="https://cdn.lockie.dev/cider-13.jpg" alt="Changelog">
<img src="https://cdn.lockie.dev/cider-14.jpg" alt="Auto update dialog">
    
The whole process avoids having to ask for user permission making the update procedure simple and seamless, completely without user intervention.

<img src="https://cdn.lockie.dev/cider-autoupdate.webp" alt="Cider auto update process">

## Internal Tools

Internal tools were created to facilitate the development of the project:

- [swift-precompiler](https://github.com/lockieluke/swift-precompiler) for embedding static content in Swift similar to [include_str!](https://doc.rust-lang.org/std/macro.include_str.html) in Rust
- coke(Close sourced) for patching and installing CocoaPods from Git repositories with a simple Command Line Interface(CLI)

Much of this repository consists of custom build toolchains like [Taskfile.yml](./Taskfile.yml) which contains all the build scripts required to build the project.  I essentially replicated a monorepo code structure without knowing what a monorepo was.

## Gallery
<img src="https://cdn.lockie.dev/cider-16.jpg" alt="Cider sign in">
<img src="https://cdn.lockie.dev/cider-15.jpg" alt="Cider sign in onboarding">
<img src="https://cdn.lockie.dev/cider-12.jpg" alt="Cider sign in debug">
<img src="https://cdn.lockie.dev/cider-11.jpg" alt="Cider sign in">
<img src="https://cdn.lockie.dev/cider-onboarding.webp" alt="Cider onboarding">
<img src="https://cdn.lockie.dev/cider-bg-effect.webp" alt="Cider background effect">
<img src="https://cdn.lockie.dev/cider-fluid-animation.webp" alt="Cider fluid animation">
<img src="https://cdn.lockie.dev/cider-volume-slider.webp" alt="Cider volume slider">

### Compiling Cider
[![Compiling Cider](https://img.youtube.com/vi/nFkjMmgB0K0/0.jpg)](https://www.youtube.com/watch?v=nFkjMmgB0K0)
[![AirPlay in Cider](https://img.youtube.com/vi/fEDXY3thqmQ/0.jpg)](https://www.youtube.com/watch?v=fEDXY3thqmQ)
