//
//  WelcomeSheetView.swift
//  dime
//
//  Created by Rafael Soh on 22/8/22.
//

import Foundation
import SwiftUI

struct WelcomeSheetFeatureRow: Hashable {
    let icon: String
    let header: String
    let subtitle: String
}

struct WelcomeSheetView: View {
    @Environment(\.dismiss) var dismiss

    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.dateCreated)
    ]) private var categories: FetchedResults<Category>

    @State var firstPage = true
    @State var visibleLines: Int = 0

    let timer = Timer.publish(every: 0.16, on: .main, in: .common).autoconnect()

    let welcomeFeatures = [
        WelcomeSheetFeatureRow(icon: "list.bullet.rectangle.fill", header: "welcome_header_1", subtitle: "welcome_subtitle_1"),
        WelcomeSheetFeatureRow(icon: "chart.bar.xaxis", header: "welcome_header_2", subtitle: "welcome_subtitle_2"),
        WelcomeSheetFeatureRow(icon: "archivebox.fill", header: "welcome_header_3", subtitle: "welcome_subtitle_3")
    ]

    var body: some View {
        VStack {
            if firstPage {
                VStack(spacing: 50) {
                    VStack(spacing: 2) {
                        Image("AppIcon1_EG")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .padding(.bottom, 20)

                        Text("dime_name")
                            .font(.system(size: 30, weight: .medium, design: .rounded))
                            .foregroundColor(Color.PrimaryText)

                        Text("Version \(UIApplication.appVersion ?? "") (\(UIApplication.buildNumber ?? ""))")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                            .padding(.bottom, 15)
                    }
                    .frame(height: UIScreen.main.bounds.height / 3.4, alignment: .bottom)
                    .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(welcomeFeatures.indices, id: \.self) { rowIndex in
                            if rowIndex < visibleLines {
                                HStack(alignment: .top, spacing: 15) {
                                    Image(systemName: welcomeFeatures[rowIndex].icon)
                                        .font(.system(size: 25, weight: .regular))
                                        .foregroundColor(Color.SubtitleText)
                                        .frame(width: 40, alignment: .leading)
                                        .offset(y: 2)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(LocalizedStringKey(welcomeFeatures[rowIndex].header))
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.PrimaryText)

                                        Text(LocalizedStringKey(welcomeFeatures[rowIndex].subtitle))
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .fixedSize(horizontal: false, vertical: true)
                                            .foregroundColor(Color.SubtitleText)
                                    }
                                }
                                .transition(AnyTransition.opacity.combined(with: .move(edge: .leading)))
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .onReceive(timer) { _ in
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if visibleLines < 3 {
                                visibleLines += 1
                            } else {
                                timer.upstream.connect().cancel()
                            }
                        }
                    }

                    Button {
                        withAnimation {
                            firstPage = false
                        }
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.LightIcon)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.DarkBackground))
                    }
                }
                .padding(30)
            } else {
                CategoryView(mode: .welcome)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.PrimaryBackground)
    }
}
