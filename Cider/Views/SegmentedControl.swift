//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

enum SegmentedControlIcon : String {
    
    case Home = "house";
    case ListenNow = "play.circle";
    case Browse = "globe";
    case Radio = "dot.radiowaves.left.and.right";
    
}

// Stops working when hot reload is triggered
struct SegmentedControl: View {
    
    @ObservedObject private var iO = Inject.observer
    
    public var items: [String] = []
    public var icons: [SegmentedControlIcon] = []
    
    @State private var selectedItem: Int = 0
    @State private var hoveredItem: Int = -1
    @State private var selectedWidth: CGFloat = 0
    
    @State private var segmentedControlsSize: [CGSize] = []
    @State private var segmentedSize = CGSize(width: 0, height: 0)
    @State private var currentSegmentedSize = CGSize()
    @State private var offsetPositions: [CGRect] = []
    @State private var currentOffsetPosition = CGRect()
    
    var body: some View {
        ZStack {
            HStack {
                let thisControlSize = segmentedControlsSize.isEmpty ? CGSize(width: 0, height: 0) : segmentedControlsSize[selectedItem]
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("SecondaryColour"))
                    .frame(width: thisControlSize.width, height: thisControlSize.height)
                    .offset(x: currentOffsetPosition.minX, y: 0)
                Spacer()
            }
            
            HStack {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    let isSelected = selectedItem == index
                    SegmentedControlItem(item: item, icon: icons[index], isSelected: isSelected, selectedCB: {
                        self.selectedItem = index
                        withAnimation(.spring().speed(1.30)) {
                            self.currentOffsetPosition = offsetPositions[index]
                            self.currentSegmentedSize = segmentedControlsSize[index]
                        }
                    })
                    .overlay {
                        GeometryReader { geometry in
                            EmptyView()
                                .onChange(of: geometry.frame(in: .global)) { newPosition in
                                    self.offsetPositions[index] = newPosition
                                    
                                    if self.selectedItem == index {
                                        self.currentOffsetPosition = offsetPositions[index]
                                    }
                                }
                                .onChange(of: geometry.size) { newSize in
                                    self.segmentedControlsSize[index] = newSize
                                    
                                    if self.selectedItem == index {
                                        self.currentSegmentedSize = segmentedControlsSize[index]
                                    }
                                }
                        }
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("SecondaryColour"), lineWidth: 1.5)
                    .padding([.horizontal, .vertical], -3)
                
                GeometryReader { geometry in
                    EmptyView()
                        .onChange(of: geometry.size) { newSize in
                            self.segmentedSize = newSize
                        }
                }
            }
        }
        .onAppear {
            self.segmentedControlsSize = [CGSize](repeating: .zero, count: self.items.count)
            self.offsetPositions = [CGRect](repeating: .zero, count: self.items.count)
        }
        .enableInjection()
    }
}

struct SegmentedControlItem: View {
    
    @ObservedObject private var iO = Inject.observer
    
    public var item: String
    public var icon: SegmentedControlIcon
    public var isSelected: Bool
    public var selectedCB: (() -> Void)? = nil
    public var sizeChanged: ((_ newSize: CGSize) -> Void)? = nil
    public var positionUpdated: ((_ newPosition: CGRect) -> Void)? = nil
    
    @State private var isHovered = false
    @State private var segSize = CGSize(width: 0, height: 0)
    
    var body: some View {
        HStack {
            Image(systemName: icon.rawValue)
                .font(.system(size: 12))
                .foregroundColor(.white)
            Text(item)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, 5).background(isHovered ? AnyView(RoundedRectangle(cornerRadius: 7).fill(Color("SecondaryColour").opacity(0.5))) : AnyView(EmptyView()))
        .overlay {
            GeometryReader { geomtry in
                EmptyView()
                    .onChange(of: geomtry.size) { newSize in
                        self.segSize = newSize
                        self.sizeChanged?(newSize)
                    }
            }
        }
        .onTapGesture {
            self.selectedCB?()
            self.sizeChanged?(self.segSize)
        }
        .onHover { isHovered in
            self.isHovered = isSelected ? false : isHovered
        }
        .enableInjection()
    }
    
}

struct SegmentedControl_Previews: PreviewProvider {
    static var previews: some View {
        SegmentedControl()
    }
}
