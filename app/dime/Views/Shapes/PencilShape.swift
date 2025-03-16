//
//  File.swift
//  dime
//
//  Created by Rafael Soh on 24/10/23.
//

import Foundation
import SwiftUI

struct PencilView: View {
    var text: String = "2.5k"

    var flagLength: CGFloat = 10
    var horizontalPadding: CGFloat = 5
    var fontSize: CGFloat = 12

    var width: CGFloat {
        return text.widthOfRoundedString(size: fontSize, weight: .bold) + flagLength + horizontalPadding + 2
    }

    var body: some View {
            ZStack(alignment: .leading) {
                Pencil(flagLength: flagLength, offsetLength: 3, cornerRadius: 5)
                    .fill(Color.SubtitleText)
                    .frame(width: width, height: 20)

                Text(text)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.PrimaryText)
                    .padding(.horizontal, horizontalPadding)

            }
    }
}

struct Pencil: Shape {
    var flagLength: CGFloat
    var offsetLength: CGFloat
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let height = rect.height / 2

        var path = Path()

//        path.move(to: CGPoint(x: cornerRadius, y: rect.minY))
        path.move(to: CGPoint(x: rect.width - (offsetLength + flagLength), y: rect.minY))

        let angle = atan(height/flagLength)

        path.addQuadCurve(to: CGPoint(x: rect.width - (flagLength - offsetLength * cos(angle)), y: offsetLength * sin(angle)), control: CGPoint(x: rect.width - flagLength, y: rect.minY))

        path.addLine(to: CGPoint(x: rect.width - offsetLength * cos(angle), y: height - offsetLength * sin(angle)))

        path.addQuadCurve(to: CGPoint(x: rect.width - offsetLength * cos(angle), y: height + offsetLength * sin(angle)), control: CGPoint(x: rect.width, y: height))

        path.addLine(to: CGPoint(x: rect.width - (flagLength - offsetLength * cos(angle)), y: rect.height - offsetLength * sin(angle)))

        path.addQuadCurve(to: CGPoint(x: rect.width - (offsetLength + flagLength), y: rect.maxY), control: CGPoint(x: rect.width - flagLength, y: rect.maxY))

        path.addLine(to: CGPoint(x: cornerRadius, y: rect.maxY))

        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.height - cornerRadius), control: CGPoint(x: rect.minX, y: rect.maxY))

        path.addLine(to: CGPoint(x: rect.minX, y: cornerRadius))

        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))

        path.closeSubpath()

        return path
    }
}
