//
//  TestView.swift
//  xpenz
//
//  Created by Rafael Soh on 21/5/22.

// this is where i test shit out
import Foundation
import SwiftUI

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
