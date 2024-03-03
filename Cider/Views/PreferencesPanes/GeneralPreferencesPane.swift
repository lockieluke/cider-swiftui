//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Settings
import Inject
import Defaults
import SFSafeSymbols

struct GeneralPreferencesPane: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var cacheModal: CacheModal
    @EnvironmentObject private var navigationModal: NavigationModal
    
    @Default(.shareAnalytics) private var shareAnalytics
    @Default(.rootStacksSleepSeconds) private var rootStacksSleepSeconds
    
    struct DataShareTypeView: View {
        
        @ObservedObject private var iO = Inject.observer
        
        var systemSymbol: SFSymbol
        var label: String
        
        var body: some View {
            HStack(alignment: .center, spacing: 15) {
                Image(systemSymbol: systemSymbol)
                Text(label)
                    .lineLimit(4)
            }
            .frame(maxWidth: 350)
            .padding(.vertical, 7)
            .enableInjection()
        }
    }
    
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: "") {
                Group {
                    PrefSectionText("General")
                    Defaults.Toggle("Never show donation popup", key: .neverShowDonationPopup)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    PrefSectionText("Appearance")
                    Defaults.Toggle("Use Pretendard font (Beta)", key: .usePretendardFont)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    Text("Restart is required for changes to take effect")
                        .settingDescription()
                    
                    PrefSectionText("Performance")
                    Picker("Pages sleep after", selection: $rootStacksSleepSeconds) {
                        Text("10 seconds").tag(10)
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(60 * 5)
                        Text("10 minutes").tag(60 * 10)
                    }
                    Text("Individual pages like Home and Listen Now go to sleep after the specified time of inactivity to reserve system resources")
                        .settingDescription()
                    
                    PrefSectionText("Analytics")
                    Toggle("Share usage data and device configuration", isOn: $shareAnalytics)
                        .onChange(of: self.shareAnalytics) { shareAnalytics in
                            if !shareAnalytics && !self.navigationModal.isAnalyticsPersuationPresent && !self.navigationModal.displayDisableButtonInAnalyticsPersuation {
                                self.shareAnalytics = true
                                self.navigationModal.displayDisableButtonInAnalyticsPersuation = true
                                self.navigationModal.isAnalyticsPersuationPresent = true
                            }
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    Text("Consult our [Privacy Policy](https://cider.sh/legal/privacy) to learn more about what types of data we collect.  Since this version of Cider is still in Alpha, there are [additional types of data](cider-swiftui://analytics-learn-more) that we collect for investigating crashes and improving the overall experience")
                        .settingDescription()
                    
                    Defaults.Toggle("Send Crash Reports and Performance Metrics", key: .shareCrashReports)
                        .onChange { shareCrashReports in
                            if shareCrashReports {
                                Analytics.shared.startSentry()
                            } else {
                                Analytics.shared.stopSentry()
                            }
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    Text("Performance monitoring and error tracking are powered by [Sentry](https://sentry.io/)")
                        .settingDescription()
                    
                    PrefSectionText("Cache")
                    Button {
                        self.cacheModal.clear()
                    } label: {
                        Text("Clear Cache")
                    }
                    .disabled(cacheModal.clearedCache)
                    
                    Text("\(Bundle.main.displayName) will have to refetch data next time it launches and it will take significantly more time to startup")
                        .settingDescription()
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $navigationModal.isAnalyticsPersuationPresent, onDismiss: {
            self.navigationModal.displayDisableButtonInAnalyticsPersuation = false
        }) {
            VStack(alignment: .center) {
                Button() {
                    self.navigationModal.isAnalyticsPersuationPresent = false
                } label: {
                    Image(systemSymbol: .xmarkCircleFill)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                Text("Learn more about Analytics")
                    .bold()
                    .font(.system(size: 20))
                    .padding(.vertical, 2)
                Text("Here's some types of data that we share")
                
                Spacer()
                
                DataShareTypeView(systemSymbol: .chartBarFill, label: "General usage data like what media is playing when you open the lyrics pane")
                DataShareTypeView(systemSymbol: .laptopcomputer, label: "Device configuration data like what Mac model you have, and what potential conflicting applications and processes you have running")
                DataShareTypeView(systemSymbol: .wifi, label: "Network configuration like your network speeds and your default browser setting")
                    
                Spacer()
                
                Text("By sharing your usage data and device configuration to developers at Cider, it makes it easier for us to investigate crashes and bugs especially when the app is in its early stages")
                    .multilineTextAlignment(.center)
                
                if navigationModal.displayDisableButtonInAnalyticsPersuation {
                    VStack(spacing: 10) {
                        Button {
                            self.shareAnalytics = true
                            self.navigationModal.isAnalyticsPersuationPresent = false
                        } label: {
                            Text("Keep it on")
                        }
                        .tint(.pink)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button {
                            self.shareAnalytics = false
                            self.navigationModal.isAnalyticsPersuationPresent = false
                        } label: {
                            Text("Disable anyway")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal)
            .frame(width: 450, height: navigationModal.displayDisableButtonInAnalyticsPersuation ? 500 : 450)
        }
        .enableInjection()
    }
}

struct GeneralPreferencesPane_Previews: PreviewProvider {
    static var previews: some View {
        GeneralPreferencesPane()
    }
}
