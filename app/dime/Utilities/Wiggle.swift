//
//  Wiggle.swift
//  dime
//
//  Created by Rafael Soh on 9/7/23.
//

import SwiftUI

struct AnimationUtils {
    static func wiggleAnimation(interval: TimeInterval, variance: Double) -> Animation {
        return Animation.easeInOut(duration: randomize(interval: interval, withVariance: variance)).repeatForever(autoreverses: true)
    }

    static func randomize(interval: TimeInterval, withVariance variance: Double) -> TimeInterval {
        let random = (Double(arc4random_uniform(1000)) - 500.0) / 500.0
        return interval + variance * random
    }
}

struct WiggleRotationModifier: ViewModifier {
    @Binding var isWiggling: Bool
    var rotationAmount: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: isWiggling ? rotationAmount : 0))
            .animation(isWiggling ? AnimationUtils.wiggleAnimation(interval: 0.14, variance: 0.025) : .default, value: isWiggling)
    }
}

struct WiggleBounceModifier: GeometryEffect {
    var amount: Double
    var bounceAmount: Double

    var animatableData: Double {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size _: CGSize) -> ProjectionTransform {
        let bounce = sin(.pi * 2 * animatableData) * bounceAmount
        let translationEffect = CGAffineTransform(translationX: 0, y: CGFloat(bounce))
        return ProjectionTransform(translationEffect)
    }
}

extension View {
    func wiggling(isWiggling: Binding<Bool>, rotationAmount: Double = 3, bounceAmount: Double = 1) -> some View {
        modifier(WiggleRotationModifier(isWiggling: isWiggling, rotationAmount: rotationAmount))
            .modifier(WiggleBounceModifier(amount: isWiggling.wrappedValue ? 1 : 0, bounceAmount: bounceAmount))
            .animation(isWiggling.wrappedValue ? AnimationUtils.wiggleAnimation(interval: 0.3, variance: 0.025).repeatForever(autoreverses: true) : .default, value: isWiggling.wrappedValue)
    }
}
