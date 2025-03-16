//
//  CustomTabBar.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import Foundation
import SwiftUI

struct CustomTabBar: View {
    @EnvironmentObject var appLockVM: AppLockViewModel
    @Binding var currentTab: String
    var topEdge: CGFloat
    var bottomEdge: CGFloat
    @State var addTransaction: Bool = false

    @State var checkingFace: Bool = false

    @FetchRequest(sortDescriptors: []) private var transactions: FetchedResults<Transaction>

    @State var count = 0
    @Binding var counter: Int

    var launchAdd: Bool

    @AppStorage("confetti", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var confetti: Bool = false
    @AppStorage("firstTransactionViewLaunch", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var firstLaunch: Bool = true

    @State var animate = false

    private var isZoomed: Bool {
        UIScreen.main.scale != UIScreen.main.nativeScale
    }

    var body: some View {
        HStack(spacing: 4) {
            TabButton(image: "Log", zoomed: isZoomed, currentTab: $currentTab)

            TabButton(image: "Insights", zoomed: isZoomed, currentTab: $currentTab)

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.DarkBackground.opacity(0.6))
                    .frame(width: 95, height: 68)
                    .opacity(self.animate ? 0 : 1)
                    .scaleEffect(self.animate ? 1 : 0.4)

                RoundedRectangle(cornerRadius: 20.5, style: .continuous).fill(Color.DarkBackground.opacity(0.8))
                    .frame(width: 80, height: 53)
                    .opacity(self.animate ? 0 : 1)
                    .scaleEffect(self.animate ? 1 : 0.6)

                Button {
                    let impactMed = UIImpactFeedbackGenerator(style: .light)
                    impactMed.impactOccurred()

                    addTransaction = true

                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(MyButtonStyle())
                .padding(15)
            }
            .onAppear {
                if transactions.isEmpty {
                    withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: false)) {
                        self.animate.toggle()
                    }
                }
            }
            .accessibilityLabel("Add New Transaction")

            TabButton(image: "Budget", zoomed: isZoomed, currentTab: $currentTab)

            TabButton(image: "Settings", zoomed: isZoomed, currentTab: $currentTab)
        }
        .padding(.horizontal, 15)
        .padding(.bottom, bottomEdge - 10)
        .frame(maxWidth: .infinity)
        .background(Color.PrimaryBackground)
        .fullScreenCover(isPresented: $addTransaction, onDismiss: {
            if confetti {
                if count != transactions.count {
                    counter += 1
                }
            }

            if firstLaunch {
                firstLaunch = false
            }

        }, content: {
            TransactionView(toEdit: nil)
        })
        .onChange(of: launchAdd) { _ in
            addTransaction = true
        }
        .onChange(of: addTransaction) { _ in
            if addTransaction {
                count = transactions.count
            }
        }
        .onChange(of: transactions.count) { _ in
            if !transactions.isEmpty {
                self.animate = false
            } else {
                self.animate = true
            }
        }
        .onOpenURL { url in
            guard
                url.host == "newExpense"

            else {
                return
            }

            addTransaction = true
        }
    }
}

struct MyButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color.LightIcon)
            .frame(width: 65, height: 38)
            .background(configuration.isPressed ? Color.SubtitleText : Color.DarkBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

struct BouncyButton: ButtonStyle {
    var duration: Double
    var scale: Double

    public func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
//            .scaleEffect(configuration.isPressed ? 1.3 : 1)
            .animation(.easeOut(duration: duration), value: configuration.isPressed)
    }
}

struct TabButton: View {
    var image: String
    var zoomed: Bool
    @Binding var currentTab: String

    var body: some View {
        Button {
            DispatchQueue.main.async {
                currentTab = image
            }
        } label: {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 28, maxHeight: 28)
                .animation(.easeInOut(duration: 0.3), value: currentTab)
                .frame(maxWidth: .infinity)
                .foregroundColor(currentTab == image ? Color.DarkIcon : Color.GreyIcon)
        }
        .buttonStyle(BouncyButton(duration: 0.3, scale: 0.6))
        .accessibilityLabel("\(image) tab")
        .accessibilityAddTraits(
            currentTab == image
                ? [.isButton, .isSelected]
                : .isButton
        )
    }
}
