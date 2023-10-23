//
//  UpdateSheet.swift
//  dime
//
//  Created by Rafael Soh on 13/9/23.
//

import Foundation
import SwiftUI

struct UpdateAlert: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var systemColorScheme

    @State private var offset: CGFloat = 0

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var bottomEdge: Double = 15

    @State var opacity = 0.0

    let welcomeFeatures = [
        WelcomeSheetFeatureRow(icon: "appclip", header: "Siri Shorcuts", subtitle: "3 new Siri shortcuts allow you to conveniently add new transactions or access insights."),
        WelcomeSheetFeatureRow(icon: "arrow.down.doc.fill", header: "Data Import", subtitle: "Transfer pre-existing logs from other applications with a step-by-step guide."),
        WelcomeSheetFeatureRow(icon: "sun.haze.fill", header: "Future Transactions", subtitle: "With date restrictions lifted, log and view upcoming expenses/incomes."),
        WelcomeSheetFeatureRow(icon: "app.gift.fill", header: "App Icons", subtitle: "Choose from 3 new skeuomorphic icons beautifully crafted by the talented @rudra_dsigns."),
        WelcomeSheetFeatureRow(icon: "circle.grid.2x2.fill", header: "Re-designed Screens", subtitle: "Budget and category creation screens have been completely reworked."),
        WelcomeSheetFeatureRow(icon: "swatchpalette.fill", header: "Custom Category Colors", subtitle: "Using the stock iOS color picker, give your categories a long-awaited aesthetic refresh."),
        WelcomeSheetFeatureRow(icon: "exclamationmark.octagon.fill", header: "New Toasts", subtitle: "Similarly, alert toasts across the app have been re-designed."),
        WelcomeSheetFeatureRow(icon: "calendar", header: "Custom Time Frames", subtitle: "Change the start of a month's cycle to align with payday.")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.PrimaryBackground.opacity(opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeIn(duration: 0.15)) {
                        opacity = 0
                        offset += 300
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        dismiss()
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation {
                            opacity = 0.4
                        }
                    }
                }

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(.callout, design: .rounded))
//                            .font(.system(size: 16))
                        Text("What's New?")
                            .font(.system(.title2, design: .rounded).weight(.medium))
//                            .font(.system(size: 22, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.PrimaryText)

                    Text("Version \(UIApplication.appVersion ?? "") (\(UIApplication.buildNumber ?? "")) · 18 Sep 2023")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
//                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.SubtitleText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .topTrailing) {
                    Button {
                        withAnimation(.easeIn(duration: 0.15)) {
                            opacity = 0
                            offset += 300
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
//                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(7)
                            .background(Color.SecondaryBackground, in: Circle())
                            .contentShape(Circle())
                    }
                    .offset(x: 5, y: -5)
                }
                .padding(.bottom, 15)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(welcomeFeatures, id: \.self) { row in
                            HStack(alignment: .top, spacing: 15) {
                                Image(systemName: row.icon)
                                    .font(.system(.title2, design: .rounded))
//                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(Color.SubtitleText)
                                    .frame(width: 35, alignment: .leading)
                                    .offset(y: 2)

                                VStack(alignment: .leading, spacing: 3.5) {
                                    Text(LocalizedStringKey(row.header))
                                        .font(.system(.body, design: .rounded).weight(.medium))
//                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.PrimaryText)

                                    Text(LocalizedStringKey(row.subtitle))
                                        .font(.system(.subheadline, design: .rounded).weight(.medium))
//                                        .font(.system(size: 16, weight: .regular, design: .rounded))
//                                            .lineSpacing(0.6)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .foregroundColor(Color.SubtitleText)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .frame(height: 300)

                Text("Special thanks to \(makeAttributedString()) for contributing")
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundColor(Color.SubtitleText)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
            .offset(y: offset)
            .padding(.horizontal, 17)
            .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .edgesIgnoringSafeArea(.all)
        .background(BackgroundBlurView())
    }

    func makeAttributedString() -> AttributedString {
        var string = AttributedString("Yumi")
        string.foregroundColor = Color.PrimaryText
        string.link = URL(string: "https://yumiizumi.com/")

        return string
    }
}
