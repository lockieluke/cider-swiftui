//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import AlertToast
import SwiftUI
import Throttler
import Inject
import Defaults
import SFSafeSymbols

struct ContentView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @Default(.launchedBefore) private var launchedBefore
    @Default(.lastLaunchDate) private var lastLaunchDate
    @Default(.neverShowDonationPopup) private var neverShowDonationPopup
    @Default(.lastShownChangelogs) private var lastShownChangelogs
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
#if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
    @EnvironmentObject private var authModal: AuthModal
    @EnvironmentObject private var cacheModal: CacheModal
#endif
    
    @StateObject private var searchModal = SearchModal()
    @StateObject private var personalisedData = PersonalisedData()
    @StateObject private var toastModal = ToastModal()
    @StateObject private var updateHelper = UpdateHelper.shared
    
    @State private var displayAskDonationAgainToast: Bool = false
    
    private func displayChangelogsIfNeeded() {
        if lastShownChangelogs.isNil || lastShownChangelogs != "\(Bundle.main.appVersion)-\(Bundle.main.appBuild)" {
            self.navigationModal.isChangelogsViewPresent = true
        }
    }
    
    var body: some View {
        let shouldPresentUpdateToast = Binding(get: { !self.navigationModal.showSidebar && self.updateHelper.updateNeeded }, set: { _ in })
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
        .toast(isPresenting: $displayAskDonationAgainToast, duration: 5) {
            AlertToast(displayMode: .hud, type: .systemImage(SFSymbol.clockArrowCirclepath.rawValue, .yellow), title: "We'll remind you tomorrow")
        }
        .toast(isPresenting: shouldPresentUpdateToast, tapToDismiss: true, alert: {
            AlertToast(
                displayMode: .hud,
                type: .systemImage(SFSymbol.arrowDownAppFill.rawValue, .green),
                title: "Ready to update",
                subTitle: "New update available"
            )
        }, onTap: {
            self.updateHelper.updateInitiaited = true
            self.navigationModal.isAboutViewPresent = true
        })
        .toast(isPresenting: $toastModal.showingErrorToast, duration: toastModal.errorToast?.duration ?? 0.0) {
            let errorToast = toastModal.errorToast ?? ToastModal.ErrorToast(title: "", subtitle: "")
            return AlertToast(displayMode: .hud, type: .error(.red), title: errorToast.title, subTitle: errorToast.subtitle)
        }
        .sheet(isPresented: $navigationModal.isDonateViewPresent, onDismiss: {
            self.displayChangelogsIfNeeded()
        }) {
            DonateView() {
                self.displayAskDonationAgainToast = true
            }
        }
        .sheet(isPresented: $navigationModal.isAboutViewPresent) {
            AboutView()
        }
        .sheet(isPresented: $navigationModal.isChangelogsViewPresent) {
            ChangeLogsView()
        }
        .environmentObject(searchModal)
        .environmentObject(navigationModal)
        .environmentObject(personalisedData)
        .environmentObject(toastModal)
        .onAppear {
            if !self.launchedBefore {
                self.navigationModal.inOnboardingExperience = true
                return
            }
            
            // Ask for donation once a day
            if !CommandLine.arguments.contains("-disable-donate-view") && !Calendar.current.isDateInToday(self.lastLaunchDate) && !self.neverShowDonationPopup {
                self.navigationModal.isDonateViewPresent = true
            }
            
            if !self.navigationModal.isDonateViewPresent {
                self.displayChangelogsIfNeeded()
            }
            
            self.lastLaunchDate = .now
            
            self.navigationModal.showSidebar = Defaults[.showSidebarAtLaunch]
        }
        .task {
            if self.launchedBefore {
                let timer = ParkBenchTimer()
                do {
                    let authTimer = ParkBenchTimer()
                    let userToken = try await authModal.retrieveUserToken()
                    self.mkModal.authenticateWithToken(userToken: userToken)
                    Logger.shared.info("Authentication took \(authTimer.stop()) seconds")
                    
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
#elseif os(iOS)
        ContentView()
#endif
    }
}
