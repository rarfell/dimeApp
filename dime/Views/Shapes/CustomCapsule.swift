//
//  CustomCapsule.swift
//  dime
//
//  Created by Rafael Soh on 24/10/23.
//

import Foundation
import SwiftUI

struct CustomCapsule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let radius = rect.size.height / 2
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: width - radius, y: rect.minY))
        path.addArc(center: CGPoint(x: width - radius, y: rect.midY), radius: radius, startAngle: Angle(degrees: 270), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: radius, y: rect.maxY))
        path.addArc(center: CGPoint(x: radius, y: rect.midY), radius: radius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 270), clockwise: false)

        path.closeSubpath()
        return path
    }
}

struct CustomCapsuleProgress: View {
    var percent: Double
    var width: Double
    var topStroke: Color
    var bottomStroke: Color

    var percentString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent

        return numberFormatter.string(from: NSNumber(value: percent)) ?? "0%"
    }

    var body: some View {
        ZStack {
            CustomCapsule().foregroundColor(Color.PrimaryBackground)
                .shadow(color: percent == 1 ? Color.IncomeGreen.opacity(0.6) : Color.clear, radius: 5)

            CustomCapsule()
                .stroke(bottomStroke, lineWidth: width)

            CustomCapsule()
                .trim(from: 0, to: percent)
                .stroke(percent == 1 ? Color.IncomeGreen : topStroke, style: StrokeStyle(lineWidth: width, lineCap: .round))

            Text(percentString)
                .foregroundColor(percent == 1 ? Color.IncomeGreen : topStroke)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
