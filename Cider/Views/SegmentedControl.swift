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
    case Library = "rectangle.stack";
    
}

struct SegmentedControlItemData {
    
    let title: String
    let icon: SegmentedControlIcon
    
}

// Stops working when hot reload is triggered
struct SegmentedControl: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var items: [SegmentedControlItemData] = []
    var segmentedItemChanged: ((_ currentSegmentedItem: String) -> Void)? = nil
    
    @State private var selectedItem: Int = 0 {
        didSet {
            self.segmentedItemChanged?(items[selectedItem].title)
        }
    }
    @State private var hoveredItem: Int = -1
    @State private var selectedWidth: CGFloat = .zero
    
    @State private var segmentedControlsSize: [CGSize] = []
    @State private var segmentedSize = CGSize(width: 0, height: 0)
    @State private var currentSegmentedSize = CGSize()
    @State private var offsetPositions: [CGRect] = []
    @State private var currentOffsetPosition = CGRect()
    
    var body: some View {
        ZStack {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("SecondaryColour"))
                    .frame(width: currentSegmentedSize.width, height: currentSegmentedSize.height)
                    .offset(x: currentOffsetPosition.minX, y: 0)
                Spacer()
            }
            
            HStack {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    let isSelected = selectedItem == index
                    SegmentedControlItem(item: item.title, icon: items[index].icon, isSelected: isSelected, selectedCB: {
                        self.selectedItem = index
                        withAnimation(.interactiveSpring().speed(0.55)) {
                            self.currentOffsetPosition = offsetPositions[index]
                            self.currentSegmentedSize = segmentedControlsSize[index]
                        }
                    }, sizeChanged: { newSize in
                        self.segmentedControlsSize[index] = newSize
                        
                        if self.selectedItem == index {
                            self.currentSegmentedSize = segmentedControlsSize[index]
                        }
                    })
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onChange(of: geometry.frame(in: .named("SegmentedControl"))) { newPosition in
                                    self.offsetPositions[index] = newPosition
                                    
                                    if self.selectedItem == index {
                                        self.currentOffsetPosition = offsetPositions[index]
                                    }
                                }
                                .onAppear {
                                    self.offsetPositions[index] = geometry.frame(in: .global)
                                    
                                    if self.selectedItem == index {
                                        self.currentOffsetPosition = offsetPositions[index]
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
                    Color.clear
                        .onChange(of: geometry.size) { newSize in
                            self.segmentedSize = newSize
                        }
                        .onAppear {
                            self.segmentedSize = geometry.size
                        }
                }
            }
        }
        .onAppear {
            self.segmentedControlsSize = [CGSize](repeating: .zero, count: self.items.count)
            self.offsetPositions = [CGRect](repeating: .zero, count: self.items.count)
        }
        .coordinateSpace(name: "SegmentedControl")
        .enableInjection()
    }
}

struct SegmentedControlItem: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var item: String
    var icon: SegmentedControlIcon
    var isSelected: Bool
    var selectedCB: (() -> Void)? = nil
    var sizeChanged: ((_ newSize: CGSize) -> Void)? = nil
    var positionUpdated: ((_ newPosition: CGRect) -> Void)? = nil
    
    @State private var isHovered = false
    @State private var segSize = CGSize(width: 0, height: 0)
    
    var body: some View {
        HStack {
            Image(systemName: icon.rawValue)
                .font(.system(size: 12))
                .foregroundColor(.primary)
            Text(item)
                .font(.system(size: 12))
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 5).background(isHovered ? AnyView(RoundedRectangle(cornerRadius: 7).fill(Color("SecondaryColour").opacity(0.5))) : AnyView(EmptyView()))
        .overlay {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        self.segSize = geometry.size
                        self.sizeChanged?(geometry.size)
                    }
                    .onChange(of: geometry.size) { newSize in
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
