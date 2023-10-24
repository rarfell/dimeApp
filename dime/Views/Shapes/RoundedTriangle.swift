//
//  RoundedTriangle.swift
//  dime
//
//  Created by Rafael Soh on 24/10/23.
//

import Foundation
import SwiftUI

struct RoundedTriangle: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let cornerAngle = atan(rect.height / (rect.width / 2))
        let weirdLength = cornerRadius / tan(cornerAngle / 2)

        let firstControlPointFrom = CGPoint(x: weirdLength, y: rect.minY)
//        let firstControlPoint = CGPoint(x: rect.minX, y: rect.minY)
//        let firstControlPointTo = CGPoint(x: (weirdLength * sin((CGFloat.pi / 2) - cornerAngle)), y: (weirdLength * cos((CGFloat.pi / 2) - cornerAngle)))

        var path = Path()

        let firstCentre = CGPoint(x: weirdLength, y: cornerRadius)

        path.move(to: firstControlPointFrom)
        path.addArc(center: firstCentre, radius: cornerRadius, startAngle: Angle(degrees: 270), endAngle: Angle(degrees: 270) - Angle(radians: CGFloat.pi - cornerAngle), clockwise: true)
//        path.addQuadCurve(to: firstControlPointTo, control: firstControlPoint)

        let weirdHypot = cornerRadius / tan((CGFloat.pi / 2) - cornerAngle)

        let weirdWidth = weirdHypot * cos(cornerAngle)
        let weirdHeight = weirdHypot * sin(cornerAngle)

        let secondControlPointFrom = CGPoint(x: (rect.width / 2) - weirdWidth, y: rect.height - weirdHeight)
//        let secondControlPoint = CGPoint(x: rect.midX, y: rect.maxY)
//        let secondControlPointTo = CGPoint(x: ((rect.width / 2) + weirdWidth), y: (rect.height - weirdHeight))

        let weirderLength = cornerRadius / sin((CGFloat.pi / 2) - cornerAngle)
        let secondCentre = CGPoint(x: rect.midX, y: rect.height - weirderLength)

        path.addLine(to: secondControlPointFrom)
        path.addArc(center: secondCentre, radius: cornerRadius, startAngle: Angle(degrees: 90) + Angle(radians: cornerAngle), endAngle: Angle(degrees: 90) - Angle(radians: cornerAngle), clockwise: true)
//        path.addQuadCurve(to: secondControlPointTo, control: secondControlPoint)

        let thirdControlPointFrom = CGPoint(x: rect.width - weirdLength + (cornerRadius * cos(CGFloat.pi / 2 - cornerAngle)), y: cornerRadius + (cornerRadius * sin(CGFloat.pi / 2 - cornerAngle)))
//        let thirdControlPoint = CGPoint(x: rect.maxX, y: rect.minY)
//        let thirdControlPointTo = CGPoint(x: (rect.width - weirdLength), y: rect.minY)

        let thirdCentre = CGPoint(x: rect.width - weirdLength, y: cornerRadius)

        path.addLine(to: thirdControlPointFrom)
        path.addArc(center: thirdCentre, radius: cornerRadius, startAngle: Angle(degrees: 90) - Angle(radians: cornerAngle), endAngle: Angle(degrees: 270), clockwise: true)
//        path.addQuadCurve(to: thirdControlPointTo, control: thirdControlPoint)
        path.closeSubpath()

        return path
    }
}
