//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import SwiftUI
import Throttler
import Inject
import Defaults

struct ContentView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @Default(.launchedBefore) private var launchedBefore
    @Default(.lastLaunchDate) private var lastLaunchDate
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
#if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
    @EnvironmentObject private var discordRPCModal: DiscordRPCModal
    @EnvironmentObject private var authModal: AuthModal
    @EnvironmentObject private var cacheModal: CacheModal
#endif
    
    @StateObject private var searchModal = SearchModal()
    @StateObject private var personalisedData = PersonalisedData()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if navigationModal.inOnboardingExperience {
                    OnboardingExperienceView()
                } else {
                    NavigationContainer()
                    
                    VStack {
                        AppTitleBar()
                        
                        Spacer()
                        PlaybackView()
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .frame(height: 100)
                    }
                }
            }
            .onTapGesture {
#if canImport(AppKit)
                NSApp.keyWindow?.makeFirstResponder(nil)
#endif
            }
            .onAppear {
                if !self.navigationModal.inOnboardingExperience {
                    self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .rootViewParams))
                }
            }
            .background(VisualEffectBackground(material: .fullScreenUI).edgesIgnoringSafeArea(.top).isHidden(navigationModal.inOnboardingExperience))
            .frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.top)
            .edgesIgnoringSafeArea(.top)
        }
        .sheet(isPresented: $navigationModal.isDonateViewPresent) {
            DonateView()
        }
        .environmentObject(searchModal)
        .environmentObject(navigationModal)
        .environmentObject(personalisedData)
        .onAppear {
            if !self.launchedBefore {
                self.navigationModal.inOnboardingExperience = true
                return
            }
            
            // Ask for donation once a day
            if !CommandLine.arguments.contains("-disable-donate-view") && !Calendar.current.isDateInToday(self.lastLaunchDate) {
                self.navigationModal.isDonateViewPresent = true
            }
            
            self.lastLaunchDate = .now
        }
        .task {
            if self.launchedBefore {
                let timer = ParkBenchTimer()
                do {
                    let authTimer = ParkBenchTimer()
                    let userToken = try await authModal.retrieveUserToken()
                    self.mkModal.authenticateWithToken(userToken: userToken)
                    Logger.shared.info("Authentication took \(authTimer.stop()) seconds")
                    
                    self.discordRPCModal.agent.start()
                    self.ciderPlayback.setUserToken(userToken: userToken)
                } catch {
                    Logger.sharedLoggers[.Authentication]?.error("Failed to authenticate user: \(error)")
                }
                self.ciderPlayback.start()
                
                await self.mkModal.initStorefront()
                DispatchQueue.main.async {
                    self.mkModal.isAuthorised = true
                }
                Logger.shared.info("Cider initialised in \(timer.stop()) seconds")
            }
        }
        .enableInjection()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        ContentView()
            .environmentObject(AuthModal(mkModal: MKModal(ciderPlayback: CiderPlayback(appWindowModal: AppWindowModal(), discordRPCModal: DiscordRPCModal()), cacheModal: CacheModal()), appWindowModal: AppWindowModal(), cacheModel: CacheModal()))
#elseif os(iOS)
        ContentView()
#endif
    }
}
