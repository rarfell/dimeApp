//
//  Ring.swift
//  dime
//
//  Created by Rafael Soh on 24/10/23.
//

import Foundation
import SwiftUI

struct RingView: View {
    var percent: Double
    var width: Double
    var topStroke: Color
    var bottomStroke: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(bottomStroke, lineWidth: width)

            if percent > 0.95 {
                Circle()
                    .trim(from: 0, to: 0.95)
                    .stroke(topStroke, style: StrokeStyle(lineWidth: width, lineCap: .round))
            } else {
                Circle()
                    .trim(from: 0, to: percent)
                    .stroke(topStroke, style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
        }
        .rotationEffect(.init(degrees: -90))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
