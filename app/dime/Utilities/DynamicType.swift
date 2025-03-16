//
//  DynamicType.swift
//  dime
//
//  Created by Rafael Soh on 24/10/23.
//

import SwiftUI

extension EnvironmentValues {
    var dynamicTypeMultiplier: CGFloat {
        switch self.dynamicTypeSize {
        case .xSmall:
            0.9
        case .small:
            0.93
        case .medium:
            0.96
        case .large:
            1.0
        case .xLarge:
            1.05
        case .xxLarge:
            1.1
        case .xxxLarge:
            1.15
        default:
            1.0
        }
    }
}
