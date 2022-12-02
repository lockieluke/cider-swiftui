//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import SDWebImageSwiftUI

struct DetailedView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    
    @State private var size: CGSize = .zero
    @State private var animationFinished = false
    @State private var descriptionsShouldLoadIn = false
    
    func calculateRelativeSize() {
        self.size = CGSize(width: appWindowModal.windowSize.width * 0.03, height: appWindowModal.windowSize.height * 0.03)
    }
    
    var body: some View {
        if let mediaItem = navigationModal.detailedViewParams?.mediaItem,
           let animationNamespace = navigationModal.detailedViewParams?.geometryMatching,
           let originalSize = navigationModal.detailedViewParams?.originalSize
        {
            HStack {
                VStack {
                    ResponsiveLayoutReader { windowProps in
                        WebImage(url: mediaItem.artwork.getUrl(width: 600, height: 600))
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(5)
                            .frame(width: windowProps.size.width * 0.33, height: windowProps.size.height * 0.33)
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
                                Text("\(mediaItem.title)")
                                    .font(.system(size: 18, weight: .bold))
                                Text("\(mediaItem.curatorName)")
                                    .foregroundColor(.gray)
                                
                                Text("\(mediaItem.description)")
                                    .frame(width: size.width)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 2)
                            }
                            .isHidden(!animationFinished)
                            .transition(.move(edge: .bottom))
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
