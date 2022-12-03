//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import SDWebImageSwiftUI
import UIImageColors

struct DetailedView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    
    @State private var size: CGSize = .zero
    @State private var animationFinished = false
    @State private var descriptionsShouldLoadIn = false
    @State private var bgGlowGradientColours = Gradient(colors: [])
    
    func calculateRelativeSize() {
        self.size = CGSize(width: appWindowModal.windowSize.width * 0.03, height: appWindowModal.windowSize.height * 0.03)
    }
    
    var playButton: some View {
        Button {
            
        } label: {
            Image(systemName: "play.fill")
            Text("Play")
        }
        .buttonStyle(.borderless)
        .frame(width: 65, height: 25)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.pink))
        .modifier(SimpleHoverModifier())
    }
    
    var body: some View {
        if let mediaItem = navigationModal.detailedViewParams?.mediaItem,
           let animationNamespace = navigationModal.detailedViewParams?.geometryMatching,
           let originalSize = navigationModal.detailedViewParams?.originalSize
        {
            HStack {
                VStack {
                    ResponsiveLayoutReader { windowProps in
                        let size = CGSize(width: windowProps.size.width * 0.33, height: windowProps.size.height * 0.33)
                        
                        WebImage(url: mediaItem.artwork.getUrl(width: 600, height: 600))
                            .onSuccess { image, data, cacheType in
                                image.getColors(quality: .highest) { colours in
                                    guard let colours = colours else { return }
                                    self.bgGlowGradientColours = Gradient(colors: [Color(nsColor: colours.primary), Color(nsColor: colours.secondary), Color(nsColor: colours.detail), Color(nsColor: colours.background)])
                                }
                            }
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(5)
                            .frame(width: size.width, height: size.height)
                            .background(
                                Rectangle()
                                    .background(Color(nsColor: mediaItem.artwork.bgColour))
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(5)
                                    .multicolourGlow()
                            )
                            .aspectRatio(1, contentMode: .fill)
                            .matchedGeometryEffect(id: mediaItem.id, in: animationNamespace)
                            .onTapGesture {
                                withAnimation(.easeIn) {
                                    self.navigationModal.isInDetailedView = false
                                }
                            }
                            .onAppear {
                                self.size = originalSize
                                withAnimation(.interactiveSpring()) {
                                    self.size = CGSize(width: 250, height: 250)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
                                        withAnimation(.spring()) {
                                            self.descriptionsShouldLoadIn = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
                                            withAnimation(.spring()) {
                                                self.animationFinished = true
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                        
                        if descriptionsShouldLoadIn {
                            Group {
                                HStack {
                                    Text("\(mediaItem.title)")
                                        .font(.system(size: 18, weight: .bold))
                                    if mediaItem.playlistType == .PersonalMix {
                                        Image(systemName: "person.crop.circle").foregroundColor(Color(nsColor: mediaItem.artwork.bgColour))
                                            .font(.system(size: 18))
                                            .toolTip("Playlist curated by Apple Music")
                                            .modifier(SimpleHoverModifier())
                                    }
                                }
                                Text("\(mediaItem.curatorName)")
                                    .foregroundColor(.gray)
                                
                                if let description = mediaItem.description {
                                    Text("\(description)")
                                        .frame(width: size.width)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 2)
                                        .frame(maxWidth: 150)
                                }
                            }
                            .isHidden(!animationFinished)
                            .transition(.move(edge: .bottom))
                            
                            playButton
                        }
                    }
                    .environmentObject(appWindowModal)
                }
                .padding()
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .enableInjection()
        }
    }
}

struct DetailedView_Previews: PreviewProvider {
    static var previews: some View {
        DetailedView()
    }
}
