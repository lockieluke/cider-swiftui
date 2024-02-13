//
//  OnboardingExperienceView.swift
//  Cider
//
//  Created by Sherlock LUK on 21/09/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Lottie
import SFSafeSymbols
import Defaults
import KeychainAccess

struct AudioQualityOptions: View {
    
    @ObservedObject private var observer = Inject.observer
    
    @Default(.audioQuality) private var audioQuality
    let disabled: Bool
    let presentedAudioQuality: AudioQuality
    
    init(audioQuality: AudioQuality, disabled: Bool = false) {
        self.disabled = disabled
        self.presentedAudioQuality = audioQuality
    }
    
    var audioQualityDescription: String {
        get {
            switch self.presentedAudioQuality {
                
            case .Standard:
                return "Less detail but can help save network bandwidth"
                
                
            case .High:
                return "More detail but consumes more network bandwidth"
                
            case .Lossless:
                return "Coming soon"
                
            }
        }
    }
    
    var icon: SFSymbol {
        get {
            switch self.presentedAudioQuality {
                
            case .Standard:
                return .waveformPathEcg
                
                
            case .High:
                return .waveform
                
            case .Lossless:
                return .headphones
                
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemSymbol: icon)
                .font(.title)
            VStack(alignment: .leading) {
                Text("\(String(describing: presentedAudioQuality))")
                    .font(.title3.bold())
                
                Text(audioQualityDescription)
            }
            Spacer()
        }
        .padding()
        .frame(width: 300)
        .background {
            let selected = audioQuality == presentedAudioQuality
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("SecondaryColour"))
                .brightness(selected ? 0.4 : 0)
                .shadow(color: selected ? .pink : .clear, radius: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            self.audioQuality = self.presentedAudioQuality
        }
        .enableInjection()
    }
}

struct OnboardingExperienceView: View {
    
    @ObservedObject private var observer = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var connectModal: ConnectModal
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var authModal: AuthModal
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    @State private var currentSetupStep = -1
    @State private var animationPlaybackMode: LottiePlaybackMode = .fromProgress(.zero, toProgress: 1, loopMode: .playOnce)
    @State private var backgroundOpacity: CGFloat = .zero
    @State private var lottieOpacity: CGFloat = 1
    @State private var showingWebView: Bool = false
    @State private var showingAuthWebView: Bool = false
    @State private var escapeKeyMonitor: Any?
    
    @Default(.launchedBefore) private var launchedBefore
    
    private func dismissAnimation() {
        self.animationPlaybackMode = .pause
        withAnimation(.easeOut) {
            self.lottieOpacity = .zero
            self.backgroundOpacity = 1
            
            if let mainWindow = self.appWindowModal.nsWindow {
                mainWindow.styleMask.insert(.resizable)
                mainWindow.isMovable = true
                mainWindow.isOpaque = true
                
                if let closeButton = mainWindow.standardWindowButton(.closeButton), let minimiseButton = mainWindow.standardWindowButton(.miniaturizeButton), let zoomButton = mainWindow.standardWindowButton(.zoomButton) {
                    closeButton.isHidden = false
                    minimiseButton.isHidden = false
                    zoomButton.isHidden = false
                }
            }
            
            if let escapeKeyMonitor = self.escapeKeyMonitor {
                NSEvent.removeMonitor(escapeKeyMonitor)
            }
            self.escapeKeyMonitor = nil
            self.currentSetupStep = 0
        }
    }
    
    private func signIn(signInMethod: SignInMethod) {
        Task {
            await self.connectModal.signIn(signInMethod: signInMethod) {
                self.connectModal.cleanupWebView()
                self.showingWebView = false
                self.currentSetupStep = 2
            }
            self.showingWebView = true
        }
    }
    
    var body: some View {
        ZStack {
            LottieView(animation: try! .from(data: precompileIncludeData("@/Cider/Resources/Startup.json")))
                .playbackMode(animationPlaybackMode)
                .blur(radius: 30)
                .opacity(lottieOpacity)
            
            LottieView(animation: try! .from(data: precompileIncludeData("@/Cider/Resources/StartupText.json")))
                .playbackMode(animationPlaybackMode)
                .animationDidFinish { finished in
                    if finished {
                        self.dismissAnimation()
                    }
                }
                .opacity(lottieOpacity)
            
            VStack {
                if currentSetupStep == 0 {
                    Text("Welcome to Cider")
                        .font(.largeTitle.bold())
                    
                    Text("Let's get a few things sorted before we continue")
                        .padding(.vertical, 3)
                    
                    Button {
                        self.currentSetupStep = 1
                    } label: {
                        Image(systemSymbol: .arrowRightCircle)
                            .font(.title)
                    }
                    .buttonStyle(.borderless)
                    .padding()
                }
                
                if currentSetupStep == 1 {
                    Text("Sign in to Cider Connect")
                        .font(.largeTitle.bold())
                    
                    Text("Sign in with an existing account or create a new one to sync settings and data across devices")
                        .padding(.vertical, 3)
                    
                    VStack {
                        AuthButton(.apple) {
                            Task {
                                self.signIn(signInMethod: .apple)
                            }
                        }
                        AuthButton(.google) {
                            Task {
                                self.signIn(signInMethod: .google)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    Button("Proceed using a local account") {
                        self.currentSetupStep = 2
                    }
                    .buttonStyle(.borderless)
                }
                
                if currentSetupStep == 2 {
                    Text("Sign in to Apple Music")
                        .font(.largeTitle.bold())
                    
                    Text("Requires an active Apple Music subscription")
                        .padding(.vertical, 3)
                    
                    AuthButton(.appleMusic) {
                        self.showingAuthWebView = true
                    }
                    .padding(.vertical)
                    
                    Button("Subscribe to Apple Music") {
                        URL(string: "https://www.apple.com/uk/apple-music/")?.open()
                    }
                    .buttonStyle(.borderless)
                }
                
                if currentSetupStep == 3 {
                    Text("One more thing")
                        .font(.largeTitle.bold())
                    
                    Text("Adjust settings to your liking before proceeding")
                        .padding(.vertical, 3)
                    
                    VStack {
                        Text("Audio Quality")
                            .bold()
                        AudioQualityOptions(audioQuality: .Standard)
                        AudioQualityOptions(audioQuality: .High)
//                        AudioQualityOptions(audioQuality: .Lossless)
                    }
                    .padding(.vertical)
                    
                    VStack {
                        Text("Analytics")
                            .bold()
                        Defaults.Toggle("Share analytics with developers", key: .shareAnalytics)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        Defaults.Toggle("Send Crash Reports and Performance Metrics", key: .shareCrashReports)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        Text("Learn more about what types of data we collect in **Cider > Settings...**")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)
                            .padding(.vertical, 2)
                    }
                    .padding(.bottom)
                    
                    Button("Done") {
                        Task {
                            if let userToken = Keychain()["mk-token"] {
                                let timer = ParkBenchTimer()
                                let authTimer = ParkBenchTimer()
                                self.mkModal.authenticateWithToken(userToken: userToken)
                                Logger.shared.info("Authentication took \(authTimer.stop()) seconds")
                                
                                self.ciderPlayback.setUserToken(userToken: userToken)
                                self.ciderPlayback.start()
                                
                                await self.mkModal.initStorefront()
                                DispatchQueue.main.async {
                                    self.mkModal.isAuthorised = true
                                    self.navigationModal.inOnboardingExperience = false
                                    self.launchedBefore = true
                                    self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .rootViewParams))
                                }
                                Logger.shared.info("Cider initialised in \(timer.stop()) seconds")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .onChange(of: appWindowModal.nsWindow) { newNSWindow in
            guard let mainWindow = newNSWindow else {
                OnboardingExperience.logger.error("Failed to capture main NSWindow", displayCross: true)
                return
            }
            
            mainWindow.setFrameOriginToPositionWindowInCenterOfScreen()
            mainWindow.styleMask.remove(.resizable)
            mainWindow.isMovable = false
            mainWindow.isOpaque = false
            mainWindow.backgroundColor = .clear
            
            if let closeButton = mainWindow.standardWindowButton(.closeButton), let minimiseButton = mainWindow.standardWindowButton(.miniaturizeButton), let zoomButton = mainWindow.standardWindowButton(.zoomButton) {
                closeButton.isHidden = true
                minimiseButton.isHidden = true
                zoomButton.isHidden = true
            }
        }
        .onAppear {
            self.escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 {
                    self.dismissAnimation()
                }
                
                return event
            }
        }
        .sheet(isPresented: $showingWebView, onDismiss: {
            self.connectModal.cleanupWebView()
        }) {
            VStack {
                Button() {
                    self.showingWebView = false
                } label: {
                    Image(systemSymbol: .xmarkCircleFill)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 2)
                
                NativeComponent(self.connectModal.view)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 800, height: 600)
            .padding()
        }
        .sheet(isPresented: $showingAuthWebView) {
            VStack {
                Button() {
                    self.showingAuthWebView = false
                } label: {
                    Image(systemSymbol: .xmarkCircleFill)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 2)
                
                NativeComponent(self.authModal.webview)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: mkModal.isAuthorised) { _ in
                        self.showingAuthWebView = false
                        self.currentSetupStep += 1
                    }
                    .onAppear {
                        if self.mkModal.isAuthorised {
                            self.showingAuthWebView = false
                            self.currentSetupStep += 1
                        }
                    }
            }
            .frame(width: 800, height: 600)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: backgroundOpacity == 1 ? 0 : 15))
        .background(VisualEffectBackground(material: .fullScreenUI).edgesIgnoringSafeArea(.top).opacity(backgroundOpacity))
        .enableInjection()
    }
}

#Preview {
    OnboardingExperienceView()
}
