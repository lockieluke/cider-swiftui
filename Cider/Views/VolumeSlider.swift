//
//  CiderSlider.swift
//  Cider
//
//  Created by Sherlock LUK on 14/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

// https://github.com/pratikg29/Custom-Slider-Control/blob/main/AppleMusicSlider/AppleMusicSlider/VolumeSlider.swift
struct VolumeSlider<T: BinaryFloatingPoint>: View {
    
    @Binding var value: T
    let inRange: ClosedRange<T>
    let activeFillColor: Color
    let fillColor: Color
    let emptyColor: Color
    let height: CGFloat
    let onEditingChanged: (Bool) -> Void
    
    @State private var localRealProgress: T = 0
    @State private var localTempProgress: T = 0
    @State private var isHovering = false
    @GestureState private var isActive: Bool = false
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        GeometryReader { bounds in
            let shouldExpand = isActive || isHovering
            
            ZStack {
                HStack {
                    Image(systemName: value == 0.0 ? "speaker.slash.fill" : "speaker.fill")
                        .font(.system(.body))
                        .foregroundColor(shouldExpand ? activeFillColor : fillColor)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                self.localRealProgress = 0.0
                                self.value = 0.0
                                self.onEditingChanged(false)
                            }
                        }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .center) {
                            Capsule()
                                .fill(emptyColor)
                            Capsule()
                                .fill(shouldExpand ? activeFillColor : fillColor)
                                .mask({
                                    HStack {
                                        Rectangle()
                                            .frame(width: max(geo.size.width * CGFloat((localRealProgress + localTempProgress)), 0), alignment: .leading)
                                        Spacer(minLength: 0)
                                    }
                                })
                        }
                    }
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(shouldExpand ? activeFillColor : fillColor)
                }
                .frame(width: isActive ? bounds.size.width * 1.04 : bounds.size.width, alignment: .center)
                //                .shadow(color: .black.opacity(0.1), radius: isActive ? 20 : 0, x: 0, y: 0)
                .animation(animation, value: isActive)
            }
            .frame(width: bounds.size.width, height: bounds.size.height * 0.8, alignment: .center)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($isActive) { value, state, transaction in
                    state = true
                }
                .onChanged { gesture in
                    self.localTempProgress = T(gesture.translation.width / bounds.size.width)
                    self.value = max(min(self.getPrgValue(), self.inRange.upperBound), self.inRange.lowerBound)
                    self.onEditingChanged(true)
                }.onEnded { value in
                    self.localRealProgress = max(min(self.localRealProgress + self.localTempProgress, 1), 0)
                    self.localTempProgress = 0
                })
            .onChange(of: isActive) { _ in
                self.value = max(min(self.getPrgValue(), self.inRange.upperBound), self.inRange.lowerBound)
            }
            .onHover { isHovering in
                withAnimation(self.animation) {
                    self.isHovering = isHovering
                }
            }
            .onAppear {
                self.localRealProgress = self.getPrgPercentage(self.value)
            }
            .onChange(of: value) { newValue in
                if !self.isActive {
                    self.localRealProgress = self.getPrgPercentage(newValue)
                }
            }
        }
        .frame(height: isActive ? height * 1.8 : height, alignment: .center)
        .enableInjection()
    }
    
    private var animation: Animation {
        return (self.isActive || self.isHovering) ? .spring() : .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.6)
    }
    
    private func getPrgPercentage(_ value: T) -> T {
        let range = self.inRange.upperBound - self.inRange.lowerBound
        let correctedStartValue = value - self.inRange.lowerBound
        let percentage = correctedStartValue / range
        return percentage
    }
    
    private func getPrgValue() -> T {
        return ((self.localRealProgress + self.localTempProgress) * (self.inRange.upperBound - self.inRange.lowerBound)) + self.inRange.lowerBound
    }
}
