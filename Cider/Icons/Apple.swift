//
//  Apple.swift
//  Cider
//
//  Created by Sherlock LUK on 20/08/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftUI

struct AppleIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.71042*width, y: 0.845*height))
        path.addCurve(to: CGPoint(x: 0.58208*width, y: 0.85958*height), control1: CGPoint(x: 0.66958*width, y: 0.88458*height), control2: CGPoint(x: 0.625*width, y: 0.87833*height))
        path.addCurve(to: CGPoint(x: 0.44708*width, y: 0.85958*height), control1: CGPoint(x: 0.53667*width, y: 0.84042*height), control2: CGPoint(x: 0.495*width, y: 0.83958*height))
        path.addCurve(to: CGPoint(x: 0.31958*width, y: 0.845*height), control1: CGPoint(x: 0.38708*width, y: 0.88542*height), control2: CGPoint(x: 0.35542*width, y: 0.87792*height))
        path.addCurve(to: CGPoint(x: 0.37708*width, y: 0.30458*height), control1: CGPoint(x: 0.11625*width, y: 0.63542*height), control2: CGPoint(x: 0.14625*width, y: 0.31625*height))
        path.addCurve(to: CGPoint(x: 0.50542*width, y: 0.33792*height), control1: CGPoint(x: 0.43333*width, y: 0.3075*height), control2: CGPoint(x: 0.4725*width, y: 0.33542*height))
        path.addCurve(to: CGPoint(x: 0.65417*width, y: 0.30292*height), control1: CGPoint(x: 0.55458*width, y: 0.32792*height), control2: CGPoint(x: 0.60167*width, y: 0.29917*height))
        path.addCurve(to: CGPoint(x: 0.79583*width, y: 0.37792*height), control1: CGPoint(x: 0.71708*width, y: 0.30792*height), control2: CGPoint(x: 0.76458*width, y: 0.33292*height))
        path.addCurve(to: CGPoint(x: 0.81583*width, y: 0.675*height), control1: CGPoint(x: 0.66583*width, y: 0.45583*height), control2: CGPoint(x: 0.69667*width, y: 0.62708*height))
        path.addCurve(to: CGPoint(x: 0.71*width, y: 0.84542*height), control1: CGPoint(x: 0.79208*width, y: 0.7375*height), control2: CGPoint(x: 0.76125*width, y: 0.79958*height))
        path.addLine(to: CGPoint(x: 0.71042*width, y: 0.845*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.50125*width, y: 0.30208*height))
        path.addCurve(to: CGPoint(x: 0.65708*width, y: 0.125*height), control1: CGPoint(x: 0.495*width, y: 0.20917*height), control2: CGPoint(x: 0.57042*width, y: 0.1325*height))
        path.addCurve(to: CGPoint(x: 0.50125*width, y: 0.30208*height), control1: CGPoint(x: 0.66917*width, y: 0.2325*height), control2: CGPoint(x: 0.55958*width, y: 0.3125*height))
        path.closeSubpath()
        return path
    }
}
