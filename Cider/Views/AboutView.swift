//
//  AboutView.swift
//  Cider
//
//  Created by Sherlock LUK on 10/12/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Lottie
import Inject
import Files

struct AboutView: View {

    @ObservedObject private var iO = Inject.observer
    
    enum UpdateServiceState {
        case Checking, NotNeeded, Needed, Downloading, Installing
    }
    
    @State private var updaterState: UpdateServiceState = .Checking
    @State private var downloadProgress: Double = 0.0
    @State private var newUpdateManifest: CiderUpdateManifest?
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    
    var body: some View {
        ZStack {
            Button() {
                self.dismiss()
            } label: {
                Image(systemSymbol: .xmarkCircleFill)
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(maxHeight: .infinity, alignment: .topTrailing)
            .padding()
            
            VStack {
                if let icon = NSApplication.shared.icon {
                    Image(nsImage: icon)
                }
                
                Text("**Cider** for macOS")
                    .font(.largeTitle)
                Text("Version \(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
                
                if updaterState != .Downloading && updaterState != .Installing {
                    HStack {
                        if updaterState == .Needed {
                            Image(systemSymbol: .arrowDownCircle)
                                .foregroundStyle(.green)
                        }
                        
                        if updaterState == .Checking {
                            LottieView(animation: .named("CiderSpinner"))
                                .playing(loopMode: .loop)
                                .clipShape(Rectangle())
                                .frame(width: 15, height: 15)
                                .padding(.horizontal, 2)
                            
                            Text("Checking for updates")
                        } else {
                            Text(updaterState == .Needed ? "Update available" : "You're on the latest version")
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                if updaterState == .Needed {
                    Button {
                        let logger = Logger(label: "CiderUpdater")
                        
                        if let updateManifest = self.newUpdateManifest {
                            self.updaterState = .Downloading
                            UpdateHelper.shared.downloadUpdate(manifest: updateManifest, { progress in
                                self.downloadProgress = progress
                            }, { error in
                                if let nsWindow = self.appWindowModal.nsWindow {
                                    Alert.showModal(on: nsWindow, message: "Failed to download update: \(error)", icon: .critical)
                                }
                                logger.error("Error downloading update: \(error)")
                            }, {
                                logger.success("Download complete to \(Folder.temporary.path)")
                                self.updaterState = .Installing
                                
                                Task {
                                    await UpdateHelper.shared.applyUpdate(manifest: updateManifest)
                                }
                            })
                        }
                    } label: {
                        Text("Update")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .controlSize(.large)
                    .padding(.vertical, 5)
                }
                
                if updaterState == .Downloading {
                    VStack {
                        Text("Downloading Update")
                        ProgressView(value: downloadProgress)
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                    }
                    .padding(.vertical, 2)
                }
                
                if updaterState == .Installing {
                    VStack {
                        Text("Installing Update")
                    }
                    .padding(.vertical, 2)
                }
                
                #if DEBUG
                Button {
                    self.updaterState = .Needed
                } label: {
                    Text("Simulate new update (DEBUG)")
                }
                .buttonStyle(.borderless)
                #endif
            }
        }
        .task {
            if let updateManifest = await UpdateHelper.shared.fetchPresentVersion() {
                self.newUpdateManifest = updateManifest
                self.updaterState = UpdateHelper.shared.isAppVersionOutdated(manifest: updateManifest) ? .Needed : .NotNeeded
            }
        }
        .frame(width: 480, height: 360)
        .enableInjection()
    }
}

#Preview {
    AboutView()
}
