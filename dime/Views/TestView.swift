//
//  TestView.swift
//  xpenz
//
//  Created by Rafael Soh on 21/5/22.
import SwiftUI
import Foundation

struct DonutSemicircle: Shape {
    var percent: Double

    var animatableData: Double {
        get { percent }
        set { percent = newValue }
    }

    var cornerRadius: CGFloat
    var width: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = rect.width / 2
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let cornerAngle = asin(cornerRadius / (radius - cornerRadius))
        let endAngle = Angle(degrees: 180 + (180 * percent)) - Angle(radians: cornerAngle)
        let weirdLength = sqrt(((radius - cornerRadius) * (radius - cornerRadius)) - (cornerRadius * cornerRadius))
        let weirderLength = radius - weirdLength
        let innerRadius = radius - width
        let stupidAngle = acos(((innerRadius + cornerRadius) * (innerRadius + cornerRadius) + (innerRadius + weirderLength) * (innerRadius + weirderLength) - cornerRadius * cornerRadius)/(2 * (innerRadius + cornerRadius) * (innerRadius + weirderLength)))
        let dumbassAngle = asin((cornerRadius)/(innerRadius + cornerRadius))

        var path = Path()
        path.move(to: CGPoint(x: radius - weirdLength, y: rect.maxY))
//        path.move(to:CGPoint(x: rect.width * 0.3, y: rect.maxY))

        let firstControlPoint = CGPoint(x: (radius - radius * cos(cornerAngle)), y: (rect.maxY - radius * sin(cornerAngle)))

        path.addQuadCurve(to: firstControlPoint, control: CGPoint(x: 0, y: rect.maxY))

        if endAngle > Angle(radians: CGFloat.pi + cornerAngle) {
            path.addArc(center: center, radius: radius, startAngle: Angle(radians: CGFloat.pi + cornerAngle), endAngle: endAngle, clockwise: false)
        }

        var secondControlPoint: CGPoint
        var secondControlPointTo: CGPoint
        var thirdControlPointFrom: CGPoint
        var thirdControlPoint: CGPoint
        var thirdControlPointTo: CGPoint

        if percent > 0.5 {
            secondControlPoint = CGPoint(x: radius + radius * cos(CGFloat(180 * (1 - percent)).toRadians()), y: radius - radius * sin(CGFloat(180 * (1 - percent)).toRadians()))
            secondControlPointTo = CGPoint(x: radius + weirdLength * cos(CGFloat(180 * (1 - percent)).toRadians()), y: radius - weirdLength * sin(CGFloat(180 * (1 - percent)).toRadians()))
            thirdControlPointFrom = CGPoint(x: radius + (innerRadius + weirderLength) * cos(CGFloat(180 * (1 - percent)).toRadians()), y: radius - (innerRadius + weirderLength) * sin(CGFloat(180 * (1 - percent)).toRadians()))
            thirdControlPoint = CGPoint(x: radius + innerRadius * cos(CGFloat(180 * (1 - percent)).toRadians()), y: radius - innerRadius * sin(CGFloat(180 * (1 - percent)).toRadians()))
            thirdControlPointTo = CGPoint(x: radius + innerRadius * cos(stupidAngle + CGFloat(180 * (1 - percent)).toRadians()), y: radius - innerRadius * sin(stupidAngle + CGFloat(180 * (1 - percent)).toRadians()))

        } else if percent < 0.5 {
            secondControlPoint = CGPoint(x: radius - radius * cos(CGFloat(180 * (percent)).toRadians()), y: radius - radius * sin(CGFloat(180 * (percent)).toRadians()))
            secondControlPointTo = CGPoint(x: radius - weirdLength * cos(CGFloat(180 * (percent)).toRadians()), y: radius - weirdLength * sin(CGFloat(180 * (percent)).toRadians()))
            thirdControlPointFrom = CGPoint(x: radius - (innerRadius + weirderLength) * cos(CGFloat(180 * (percent)).toRadians()), y: radius - (innerRadius + weirderLength) * sin(CGFloat(180 * (percent)).toRadians()))
            thirdControlPoint = CGPoint(x: radius - innerRadius * cos(CGFloat(180 * (percent)).toRadians()), y: radius - innerRadius * sin(CGFloat(180 * (percent)).toRadians()))
           thirdControlPointTo = CGPoint(x: radius - innerRadius * cos(-stupidAngle + CGFloat(180 * (percent)).toRadians()), y: radius - innerRadius * sin(-stupidAngle + CGFloat(180 * (percent)).toRadians()))
        } else {
            secondControlPoint = CGPoint(x: rect.midX, y: rect.minY)
            secondControlPointTo = CGPoint(x: rect.midX, y: radius - weirdLength)
            thirdControlPointFrom = CGPoint(x: rect.midX, y: radius - (innerRadius + weirderLength))
            thirdControlPoint = CGPoint(x: rect.midX, y: width)
            thirdControlPointTo = CGPoint(x: radius - innerRadius * cos(CGFloat.pi / 2 - stupidAngle), y: radius - innerRadius * sin(CGFloat.pi / 2 - stupidAngle))
        }

        path.addQuadCurve(to: secondControlPointTo, control: secondControlPoint)

        path.addLine(to: thirdControlPointFrom)
        path.addQuadCurve(to: thirdControlPointTo, control: thirdControlPoint)

        if (endAngle - Angle(radians: stupidAngle)) > Angle(radians: CGFloat.pi + dumbassAngle) {
            path.addArc(center: center, radius: innerRadius, startAngle: endAngle - Angle(radians: stupidAngle), endAngle: Angle(radians: CGFloat.pi + dumbassAngle), clockwise: true)
        }

        let fourthControlPoint = CGPoint(x: width, y: rect.maxY)
        let fourthControlPointTo = CGPoint(x: width - weirderLength, y: rect.maxY)

        path.addQuadCurve(to: fourthControlPointTo, control: fourthControlPoint)

        path.closeSubpath()
        return path
    }
}

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
        path.addArc(center: firstCentre, radius: cornerRadius, startAngle: Angle(degrees: 270), endAngle: (Angle(degrees: 270) - Angle(radians: (CGFloat.pi - cornerAngle))), clockwise: true)
//        path.addQuadCurve(to: firstControlPointTo, control: firstControlPoint)

        let weirdHypot = cornerRadius / tan((CGFloat.pi / 2) - cornerAngle)

        let weirdWidth = weirdHypot * cos(cornerAngle)
        let weirdHeight = weirdHypot * sin(cornerAngle)

        let secondControlPointFrom = CGPoint(x: ((rect.width / 2) - weirdWidth), y: (rect.height - weirdHeight))
//        let secondControlPoint = CGPoint(x: rect.midX, y: rect.maxY)
//        let secondControlPointTo = CGPoint(x: ((rect.width / 2) + weirdWidth), y: (rect.height - weirdHeight))

        let weirderLength = cornerRadius / sin((CGFloat.pi / 2) - cornerAngle)
        let secondCentre = CGPoint(x: rect.midX, y: rect.height - weirderLength)

        path.addLine(to: secondControlPointFrom)
        path.addArc(center: secondCentre, radius: cornerRadius, startAngle: (Angle(degrees: 90) + Angle(radians: cornerAngle)), endAngle: (Angle(degrees: 90) - Angle(radians: cornerAngle)), clockwise: true)
//        path.addQuadCurve(to: secondControlPointTo, control: secondControlPoint)

        let thirdControlPointFrom = CGPoint(x: rect.width - weirdLength + (cornerRadius * cos(CGFloat.pi / 2 - cornerAngle)), y: cornerRadius + (cornerRadius * sin(CGFloat.pi / 2 - cornerAngle)))
//        let thirdControlPoint = CGPoint(x: rect.maxX, y: rect.minY)
//        let thirdControlPointTo = CGPoint(x: (rect.width - weirdLength), y: rect.minY)

        let thirdCentre = CGPoint(x: rect.width - weirdLength, y: cornerRadius)

        path.addLine(to: thirdControlPointFrom)
        path.addArc(center: thirdCentre, radius: cornerRadius, startAngle: (Angle(degrees: 90) - Angle(radians: cornerAngle)), endAngle: Angle(degrees: 270), clockwise: true)
//        path.addQuadCurve(to: thirdControlPointTo, control: thirdControlPoint)
        path.closeSubpath()

        return path
    }
}

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

extension CGFloat {
    func toRadians() -> CGFloat {
        return self * CGFloat(Double.pi) / 180.0
    }
}

struct Donut: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 180), clockwise: true)

        return path
    }
}

struct TestView: View {

    @State var time = Date()
    @State var strength: Float = 2.0

    var body: some View {
        if #available(iOS 17.0, *) {
            TimelineView(.animation) { _ in
                ShaderPlaygroundShowcase()
                    .layerEffect(ShaderLibrary.chromatic_abberation_time(
                        .float(self.time.timeIntervalSinceNow),
                        .float(self.strength)
                    ), maxSampleOffset: .zero)
                    .animation(.linear(duration: 1), value: self.time)
                    .animation(.linear(duration: 1), value: self.strength)
            }
        }

    }

}

struct ShaderPlaygroundShowcase: View {
    var body: some View {
       Text("hello world")
        // .frame(width: 295, height: 360)
        // .frame(width: 295)
    }

    private var OverlayImage: some View {
        VStack {
            Image("woman")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        }
    }
}
