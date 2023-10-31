//
//  SettingsView.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import Combine
import ConfettiSwiftUI
import Foundation
import StoreKit
import SwiftUI
import UserNotifications
import WidgetKit

struct SettingsView: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var colourScheme: Int = 0
    var colourSchemeString: String {
        if colourScheme == 1 {
            return String(localized: "Light")
        } else if colourScheme == 2 {
            return String(localized: "Dark")
        } else {
            return String(localized: "System")
        }
    }

    @AppStorage("activeIcon", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var activeIcon: String = "AppIcon"
    var appIconString: String {
        if activeIcon == "AppIcon1" {
            return "v2.0"
        } else if activeIcon == "AppIcon2" {
            return "Unicorn"
        } else if activeIcon == "AppIcon3" {
            return "v1.5"
        } else {
            return "O.G."
        }
    }

    @AppStorage("firstWeekday", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var firstWeekday: Int = 1
    var firstWeekdayString: String {
        if firstWeekday == 1 {
            return String(localized: "Sunday")
        } else {
            return String(localized: "Monday")
        }
    }

    @AppStorage("showNotifications", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showNotifications: Bool = false
    @AppStorage("notificationOption", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var option: Int = 1
    var notificationString: String {
        if showNotifications {
            if option == 1 {
                return String(localized: "Mornings")
            } else if option == 2 {
                return String(localized: "Evenings")
            } else {
                return String(localized: "Custom")
            }
        } else {
            return String(localized: "Off")
        }
    }

    @EnvironmentObject var appLockVM: AppLockViewModel
    @Namespace var animation

    var iCloudString: String {
        if NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync") {
            return String(localized: "On")
        } else {
            return String(localized: "Off")
        }
    }

    @Environment(\.openURL) var openURL
    let supportEmail = SupportEmail(toAddress: "rafasohhh@gmail.com", subject: "Support Email")
    let featureRequestEmail = SupportEmail(toAddress: "rafasohhh@gmail.com", subject: "Feature Request")

    @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var numberEntryType: Int = 2

    var numberEntryString: String {
        if numberEntryType == 1 {
            return String(localized: "Type 1")
        } else {
            return String(localized: "Type 2")
        }
    }

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated: Bool = true

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!

    @AppStorage("incomeTracking", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var incomeTracking: Bool = true

    @AppStorage("showUpcomingTransactions", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showUpcoming: Bool = true

    var upcomingString: String {
        if showUpcoming {
            return String(localized: "Shown")
        } else {
            return String(localized: "Hidden")
        }
    }

    // popups

    @State var showTipJarMenu = false
    @State var showImportGuide = false
    @State var showUpdate: Bool = false

    @EnvironmentObject var tabBarManager: TabBarManager

    @EnvironmentObject var dataController: DataController

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Settings")
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .accessibility(addTraits: .isHeader)
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 5) {
                        Text("GENERAL")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 13) {
                            NavigationLink(destination: SettingsAppearanceView()) {
                                SettingsRowView(systemImage: "circle.righthalf.filled", title: "Appearance", colour: 100, optionalText: colourSchemeString)
                            }

                            NavigationLink(destination: SettingsAppIconView()) {
                                SettingsRowView(systemImage: "app.badge.fill", title: "App Icon", colour: 101, optionalText: appIconString)
                            }

                            NavigationLink(destination: SettingsNotificationsView()) {
                                SettingsRowView(systemImage: "bell.fill", title: "Notifications", colour: 102, optionalText: notificationString)
                            }

                            NavigationLink(destination: SettingsCurrencyView()) {
                                SettingsRowView(systemImage: "coloncurrencysign.square.fill", title: "Currency", colour: 103, optionalText: currency)
                            }

                            NavigationLink(destination: SettingsNumberEntryView()
                                .onAppear {
                                    withAnimation(.easeOut.speed(1.5)) {
                                        tabBarManager.navigationHideTab()
                                    }
                                }
                                .onDisappear {
                                    withAnimation(.easeOut.speed(1.5)) {
                                        tabBarManager.navigationShowTab()
                                    }
                                }
                            ) {
                                SettingsRowView(systemImage: "keyboard.fill", title: "Number Entry", colour: 104, optionalText: numberEntryString)
                            }

                            ToggleRow(icon: "faceid", color: "105", text: "Authentication", bool: appLockVM.isAppLockEnabled, onTap: {
                                appLockVM.appLockStateChange(appLockState: !appLockVM.isAppLockEnabled)
                            })

                            ToggleRow(icon: "banknote.fill", color: "106", text: "Income Tracking", bool: incomeTracking, onTap: {
                                incomeTracking.toggle()

                                if !incomeTracking {
                                    UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(false, forKey: "insightsViewIncomeFiltering")
                                    UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(3, forKey: "logInsightsType")
                                }
                            })

                            ToggleRow(icon: "centsign.circle.fill", color: "107", text: "Display Cents", bool: showCents, onTap: {
                                showCents.toggle()
                            })

                            NavigationLink(destination: SettingsUpcomingView()) {
                                SettingsRowView(systemImage: "sun.min.fill", title: "Upcoming Logs", colour: 108, optionalText: upcomingString)
                            }

                            NavigationLink(destination: SettingsWeekStartView()) {
                                SettingsRowView(systemImage: "calendar", title: "Time Frames", colour: 109)
                            }
                        }
                        .padding(10)
                        .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 25)
                    .onChange(of: currency) { _ in
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    .onChange(of: firstWeekday) { _ in
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    .onChange(of: showCents) { _ in
                        WidgetCenter.shared.reloadAllTimelines()
                    }

                    VStack(spacing: 5) {
                        Text("DATA")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 13) {
                            NavigationLink(destination: SettingsCategoryView()
                                .onAppear {
                                    withAnimation(.easeOut.speed(1.5)) {
                                        tabBarManager.navigationHideTab()
                                    }
                                }
                                .onDisappear {
                                    withAnimation(.easeOut.speed(1.5)) {
                                        tabBarManager.navigationShowTab()
                                    }
                                }

                            ) {
                                SettingsRowView(systemImage: "rectangle.grid.2x2.fill", title: "Categories", colour: 110)
                            }

                            NavigationLink(destination: SettingsCloudView()) {
                                SettingsRowView(systemImage: "icloud.fill", title: "iCloud Sync", colour: 111, optionalText: iCloudString)
                            }

//
//                            NavigationLink(destination: SettingsQuickAddWidgetView()) {
//                                SettingsRowView(systemImage: "bolt.square.fill", title: "Quick-Add Widget", colour: 115)
//                            }

                            Button {
                                showImportGuide = true
                            } label: {
                                SettingsRowView(systemImage: "square.and.arrow.down.fill", title: "Import Data", colour: 112)
                            }

                            Button {
                                exportData()
                            } label: {
                                SettingsRowView(systemImage: "square.and.arrow.up.fill", title: "Export Data", colour: 113)
                            }

                            NavigationLink(destination: SettingsEraseView()) {
                                SettingsRowView(systemImage: "xmark.bin.fill", title: "Erase Data", colour: 114)
                            }
                        }
                        .padding(10)
                        .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 25)

                    VStack(spacing: 5) {
                        Text("OTHERS")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 13) {
                            ToggleRow(icon: "hare.fill", color: "121", text: "Animated Charts", bool: animated, onTap: {
                                animated.toggle()
                            })

                            NavigationLink(destination: SettingsGoofyView()) {
                                SettingsRowView(systemImage: "flame.fill", title: "Feature Lab", colour: 122)
                            }

                            Button {
                                showTipJarMenu = true
                            } label: {
                                SettingsRowView(systemImage: "heart.fill", title: "Tip Jar", colour: 123)
                            }

                            Button {
                                supportEmail.send(openURL: openURL)
                            } label: {
                                SettingsRowView(systemImage: "ladybug.fill", title: "Report Bug", colour: 124)
                            }

                            Button {
                                featureRequestEmail.send(openURL: openURL)
                            } label: {
                                SettingsRowView(systemImage: "hand.wave.fill", title: "Feature Request", colour: 125)
                            }

                            Button {
                                let url = "https://apps.apple.com/app/id1635280255?action=write-review"
                                guard let writeReviewURL = URL(string: url)
                                else { fatalError("Expected a valid URL") }
                                UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
                            } label: {
                                SettingsRowView(systemImage: "star.fill", title: "Rate on App Store", colour: 126)
                            }

                            Button {
                                shareSheet(url: "https://apps.apple.com/app/id1635280255")
                            } label: {
                                SettingsRowView(systemImage: "shareplay", title: "Share with Friends", colour: 127)
                            }

                            Button {
                                if let url = URL(string: "https://www.x.com/budgetwithdime") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                SettingsRowView(systemImage: "bird.fill", title: "Follow Dime on X", colour: 128)
                                    .frame(maxWidth: .infinity)
                            }

                            Button {
                                if let url = URL(string: "https://www.x.com/rarfell") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                SettingsRowView(systemImage: "camera.fill", title: "Follow Rafael on X", colour: 129)
                            }
                        }
                        .padding(10)
                        .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)

                    VStack(spacing: 5) {
                        HStack(spacing: 3) {
                            Text("Version \(UIApplication.appVersion ?? "") (\(UIApplication.buildNumber ?? ""))")
                                .font(.system(.footnote, design: .rounded).weight(.medium))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.SubtitleText)

                            Text("·")
                                .font(.system(.footnote, design: .rounded).weight(.medium))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .foregroundColor(Color.SubtitleText)

                            Text("What's New")
                                .font(.system(.footnote, design: .rounded).weight(.medium))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .foregroundColor(Color.PrimaryText)
                                .onTapGesture {
                                    showUpdate = true
                                }
                        }

                        Text("Made with ❤️ by \(makeAttributedString()) from 🇸🇬")
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            .foregroundColor(Color.SubtitleText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 95)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .background(Color.PrimaryBackground)
            .fullScreenCover(isPresented: $showTipJarMenu) {
                TipJarAlert()
            }
            .fullScreenCover(isPresented: $showUpdate) {
                UpdateAlert()
            }
            .fullScreenCover(isPresented: $showImportGuide) {
                ImportDataView()
            }
        }
    }

    @ViewBuilder
    func ToggleRow(icon: String, color: String, text: String, bool: Bool, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(.body, design: .rounded))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 17))
//                .padding(5)
                .foregroundColor(.white)
                .frame(width: dynamicTypeSize > .xLarge ? 40 : 30, height: dynamicTypeSize > .xLarge ? 40 : 30, alignment: .center)
//                .font(.system(size: 14))
//                .padding(5)
//                .foregroundColor(.white)
                .background(Color(color), in: RoundedRectangle(cornerRadius: 6))

            Text(text)
                .font(.system(.body, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 17, weight: .medium, design: .rounded))
                .lineLimit(1)
                .foregroundColor(Color.PrimaryText)

            Spacer()

            ZStack(alignment: bool ? .trailing : .leading) {
                Capsule()
                    .frame(width: 42, height: 28)
                    .foregroundColor(bool ? .green : .gray.opacity(0.8))

                Circle()
                    .foregroundColor(Color.white)
                    .padding(2)
                    .frame(width: 28, height: 28)
                    .matchedGeometryEffect(id: "toggle\(color)", in: animation)
            }
            .onTapGesture {
                withAnimation {
                    onTap()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    func makeAttributedString() -> AttributedString {
        var string = AttributedString("Rafael")
        string.foregroundColor = Color.PrimaryText
        string.link = URL(string: "https://www.x.com/rarfell")

        return string
    }

    func shareSheet(url: String) {
        let url = URL(string: url)
        let activityView = UIActivityViewController(activityItems: [url!], applicationActivities: nil)

        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }

        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }
    }

    func exportData() {
        let fetchRequest = dataController.fetchRequestForExport()
        let transactions = dataController.results(for: fetchRequest)

        let fileName = "export.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Date,Note,Amount,Category,Type\n"

        for transaction in transactions {
            var string = transaction.wrappedNote
            let type: String

            if transaction.income {
                type = "Income"
            } else {
                type = "Expense"
            }

            string.removeAll(where: { $0 == "," })

            csvText += "\(transaction.wrappedDate),\(string),\(String(format: "%.2f", transaction.wrappedAmount)),\(transaction.category?.wrappedName ?? ""),\(type)\n"
        }

        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("\(error)")
        }

        var filesToShare = [Any]()
        filesToShare.append(path!)

        let av = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)

        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }

        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(av, animated: true, completion: nil)
        }
    }
}

struct TipJarAlert: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var systemColorScheme
    @EnvironmentObject var unlockManager: UnlockManager

    @State private var offset: CGFloat = 0

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var bottomEdge: Double = 15

    @State var opacity = 0.0
    @State var counter = 0

    var bottomCaption: String {
        if unlockManager.failedTransaction {
            return "Tip failed to go through, please try again!"
        } else if unlockManager.purchaseCount > 0 {
            return "Thanks a million, \(Image(systemName: "heart.fill")) Rafael"
        } else {
            return "Have a great day ahead!"
        }
    }

//    var sortedProducts: [SKProduct] {
//        let holding = unlockManager.loadedProducts.sorted {
//            $0.price.doubleValue > $1.price.doubleValue
//        }
//
//        return holding
//    }

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

            VStack {
                switch unlockManager.requestState {
                case .loading:
                    ProgressView {
                        Text("Loading")
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    }
                case .failed:
                    Text("Unable to load tip options, please try again later 🥲")
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.SubtitleText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                default:
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(.callout, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 16))
                            Text("Tip Jar")
                                .font(.system(.title2, design: .rounded).weight(.medium))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 22, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.PrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .trailing) {
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
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.SubtitleText)
                                    .padding(7)
                                    .background(Color.SecondaryBackground, in: Circle())
                                    .contentShape(Circle())
                            }
                            .offset(x: 5, y: -5)
                        }

                        Text("Hey! Dime was built by a solo student developer, and is intended to be completely free-of-charge, with no paywalls or ads. If you enjoy using Dime and want to support development, please consider a small tip.")
                            .font(.system(.callout, design: .rounded).weight(.medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.SubtitleText)
                            .padding(.bottom, 20)

                        ProductView(products: unlockManager.loadedProducts.sorted {
                            $0.price.doubleValue < $1.price.doubleValue
                        })
                        .padding(.bottom, 20)

                        Text(bottomCaption)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.SubtitleText)
                    }
                }
            }
            .padding(18)
            .animation(.easeInOut, value: unlockManager.failedTransaction)
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
            .offset(y: offset)
            .confettiCannon(counter: $counter, num: 50, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 200)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height < 0 {
                            offset = gesture.translation.height / 3
                        } else {
                            offset = gesture.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 30 {
                            withAnimation(.easeIn(duration: 0.15)) {
                                opacity = 0
                                offset += 300
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                dismiss()
                            }

                        } else {
                            withAnimation {
                                offset = 0
                            }
                        }
                    }
            )
            .padding(.horizontal, 17)
            .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
            .onChange(of: unlockManager.purchaseCount) { _ in
                counter += 1
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(BackgroundBlurView())
    }
}

struct ProductView: View {
    @EnvironmentObject var unlockManager: UnlockManager
    let products: [SKProduct]

    var body: some View {
        VStack {
            ForEach(products, id: \.self) { product in
                HStack {
                    Text(getText(product.productIdentifier))

                    Spacer()

                    Button {
                        unlock(product)
                    } label: {
                        Text(product.localizedPrice)
                            .monospacedDigit()
                            .padding(6)
                            .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .foregroundColor(.PrimaryText)
        .font(.system(.body, design: .rounded).weight(.semibold))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//        .font(.system(size: 18, weight: .semibold, design: .rounded))
    }

    func unlock(_ product: SKProduct) {
        unlockManager.buy(product: product)
    }

    func getText(_ string: String) -> String {
        if string == "com.rafaelsoh.dime.smalltip" {
            return String(localized: "☕ Coffee-Sized Tip")
        } else if string == "com.rafaelsoh.dime.mediumtip" {
            return String(localized: "🌮 Taco-Sized Tip")
        } else if string == "com.rafaelsoh.dime.largetip" {
            return String(localized: "🍕 Pizza-Sized Tip")
        } else {
            return ""
        }
    }
}

struct SettingsRowView: View {
    var systemImage: String
    var title: String
    var colour: Int
    var optionalText: String?

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(.body, design: .rounded))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 17))
//                .padding(5)
                .foregroundColor(.white)
                .frame(width: dynamicTypeSize > .xLarge ? 40 : 30, height: dynamicTypeSize > .xLarge ? 40 : 30, alignment: .center)
                .background(Color("\(colour)"), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(LocalizedStringKey(title))
                .font(.system(.body, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 17, weight: .medium, design: .rounded))
                .lineLimit(1)
                .foregroundColor(Color.PrimaryText)

            Spacer()

            if optionalText != nil {
                Text(optionalText!)
                    .font(.system(.body, design: .rounded))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.DarkIcon.opacity(0.6))
                    .layoutPriority(1)
                    .padding(.trailing, -8)
            }

            Image(systemName: "chevron.forward")
                .font(.system(.subheadline, design: .rounded))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 15))
                .foregroundColor(.DarkIcon.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsAppearanceView: View {
    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var colourScheme: Int = 0
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    let options = ["System", "Light", "Dark"]

    @Namespace var animation

    var body: some View {
        VStack(spacing: 10) {
            Text("Appearance")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { option in
                    HStack {
                        Text(LocalizedStringKey(options[option]))
                            .font(.system(.body, design: .rounded))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(Color.PrimaryText)

                        Spacer()

                        if colourScheme == option {
                            Image(systemName: "checkmark")
                                .font(.system(.subheadline, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 15))
                                .foregroundColor(.DarkIcon.opacity(0.6))
                                .matchedGeometryEffect(id: "tick", in: animation)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.15)) {
                            colourScheme = option
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(.vertical, 9)
                    .overlay(alignment: .bottom) {
                        if option < (options.count - 1) {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
            .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

            Text("Close and reload app for change to take effect.")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color.SubtitleText)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
    }
}

struct AppIconBundle: Hashable {
    let actualFileName: String
    let exampleFileName: String
    let displayName: String
    let displaySubtitle: String
}

struct SettingsAppIconView: View {
    @AppStorage("activeIcon", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var activeIcon: String = "AppIcon"
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    let options: [AppIconBundle] = [
        AppIconBundle(actualFileName: "AppIcon1", exampleFileName: "AppIcon1_EG", displayName: "V2.0", displaySubtitle: "Designed by the brilliant @rudra_dsigns, check out his work on Twitter."),
        AppIconBundle(actualFileName: "AppIcon2", exampleFileName: "AppIcon2_EG", displayName: "Unicorn", displaySubtitle: "Dime definitely isn't becoming one but it never hurts to keep dreaming."),
        AppIconBundle(actualFileName: "AppIcon3", exampleFileName: "AppIcon3_EG", displayName: "V1.5", displaySubtitle: "An early prototype also designed by @rudra_dsigns that I kinda fancy."),
        AppIconBundle(actualFileName: "AppIcon4", exampleFileName: "AppIcon4_EG", displayName: "O.G.", displaySubtitle: "Haphazardly put together in under 30 minutes, the original Dime icon.")
    ]

    @State private var position: Int?

    @Namespace var animation

    var body: some View {
        VStack(spacing: 10) {
            Text("App Icon")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { index in
                    HStack(spacing: 13) {
                        Image(options[index].exampleFileName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(options[index].displayName)
                                .font(.system(.body, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.PrimaryText)

                            Text(options[index].displaySubtitle)
                                .font(.system(.caption, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(Color.SubtitleText)
                        }

                        Spacer()

                        if activeIcon == options[index].actualFileName {
                            Image(systemName: "checkmark")
                                .font(.system(.subheadline, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 15))
                                .foregroundColor(.DarkIcon.opacity(0.6))
                                .matchedGeometryEffect(id: "tick", in: animation)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(.subheadline, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 15))
                                .foregroundColor(.SettingsBackground)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
//                            print(options[index].actualFileName)
                            activeIcon = options[index].actualFileName
                        }
                    }
                    .padding(.vertical, 15)
                    .overlay(alignment: .bottom) {
                        if index < (options.count - 1) {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
            .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
            .onChange(of: activeIcon) { newValue in
                UIApplication.shared.setAlternateIconName(newValue)
            }

//            HStack {
//                ForEach(options, id: \.self) { option in
//                    Image(option.exampleFileName)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: 70, height: 70)
//                        .clipShape(RoundedRectangle(cornerRadius: 18))
//                        .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)
//                        .overlay {
//                            if activeIcon == option.actualFileName {
//                                RoundedRectangle(cornerRadius: 20)
//                                    .stroke(Color.Outline, lineWidth: 2)
//                                    .frame(width: 74, height: 74)
//                            }
//                        }
//                        .onTapGesture {
//                            withAnimation {
//                                activeIcon = option.actualFileName
//                            }
//                        }
//                }
//            }
//            .frame(maxWidth: .infinity)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
    }
}

struct SettingsCurrencyView: View {
    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currencyCode: String = Locale.current.currencyCode!
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    let currencies = Currency.allCurrencies

    @Namespace var animation

    var body: some View {
        VStack(spacing: 10) {
            Text("Currencies")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }
                .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                ScrollViewReader { value in
                    VStack(spacing: 0) {
                        ForEach(currencies, id: \.self) { currency in
                            HStack(spacing: 10) {
                                Text(currency.code)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.SubtitleText)
                                    .lineLimit(1)
//                                    .layoutPriority(1)
                                    .frame(width: dynamicTypeSize > .xLarge ? 55 : 45, alignment: .leading)
                                Text(currency.name)
                                    .font(.system(.body, design: .rounded))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.PrimaryText)
                                    .lineLimit(1)

                                Spacer()

                                if currency.code == currencyCode {
                                    Image(systemName: "checkmark")
                                        .font(.system(.subheadline, design: .rounded))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                        .font(.system(size: 15))
                                        .foregroundColor(.DarkIcon.opacity(0.6))
                                        .matchedGeometryEffect(id: "tick", in: animation)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeIn(duration: 0.15)) {
                                    currencyCode = currency.code
                                }

                                NSUbiquitousKeyValueStore.default.set(currency.code, forKey: "currency")

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            }
                            .padding(.vertical, 9)
                            .overlay(alignment: .bottom) {
                                if currency != currencies.last {
                                    Divider()
                                }
                            }
                            .padding(.horizontal, 15)
                            .id(currency.code)
                        }
                    }
                    .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
                    .padding(.bottom, 60)
                    .onAppear {
                        value.scrollTo(currencyCode, anchor: .center)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
    }
}

struct SettingsWeekStartView: View {
    @AppStorage("firstWeekday", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var firstWeekday: Int = 1
    @AppStorage("firstDayOfMonth", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var firstDayOfMonth: Int = 1
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    let options = ["Sunday", "Monday"]

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var fontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall:
            return 14
        case .small:
            return 15
        case .medium:
            return 16
        case .large:
            return 17
        case .xLarge:
            return 19
        case .xxLarge:
            return 21
        case .xxxLarge:
            return 23
        default:
            return 23
        }
    }

    var scrollViewHeight: CGFloat {
        return (("Start".heightOfRoundedString(size: fontSize, weight: .regular) + 18) * 6) - 1
    }

    @Namespace var animation

    var body: some View {
        VStack(spacing: 10) {
            Text("Time Frames")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }
                .padding(.bottom, 20)

            Text("Start of Week")
                .font(.system(.body, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(Color.SubtitleText)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { option in
                    HStack {
                        Text(LocalizedStringKey(options[option]))
                            .font(.system(.body, design: .rounded))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(Color.PrimaryText)

                        Spacer()

                        if firstWeekday == (option + 1) {
                            Image(systemName: "checkmark")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 15))
                                .foregroundColor(.DarkIcon.opacity(0.6))
                                .matchedGeometryEffect(id: "tick", in: animation)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        DispatchQueue.main.async {
                            withAnimation(.easeIn(duration: 0.15)) {
                                firstWeekday = (option + 1)
                            }
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding(.vertical, 9)
                    .overlay(alignment: .bottom) {
                        if option < (options.count - 1) {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
            .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
            .padding(.bottom, 30)

//            Text("Close and reload app for change to take effect.")
//                .font(.system(size: 12, weight: .medium, design: .rounded))
//                .foregroundColor(Color.SubtitleText)
//                .padding(.horizontal, 15)
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//
            Text("Start of Month")
                .font(.system(.body, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(Color.SubtitleText)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(showsIndicators: false) {
                ScrollViewReader { value in
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(1 ..< 29) { day in

                            HStack {
                                Text("\(getOrdinal(day)) of month")
                                    .font(.system(.body, design: .rounded))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                    .foregroundColor(Color.PrimaryText)

                                Spacer()

                                if firstDayOfMonth == day {
                                    Image(systemName: "checkmark")
                                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                        .font(.system(size: 15))
                                        .foregroundColor(.DarkIcon.opacity(0.6))
                                        .matchedGeometryEffect(id: "tick2", in: animation)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    withAnimation(.easeIn(duration: 0.15)) {
                                        firstDayOfMonth = day
                                    }
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            }
                            .padding(.vertical, 9)
                            .id(day)
                            .overlay(alignment: .bottom) {
                                if day < 28 {
                                    Divider()
                                        .offset(y: 1)
                                }
                            }
                        }
                    }
                    .onAppear {
                        value.scrollTo(firstDayOfMonth)
                    }
                }
            }
            .padding(.horizontal, 15)
            .frame(height: scrollViewHeight)
            .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

            Text("Close and reload app for change to take effect.")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color.SubtitleText)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
    }

    func getOrdinal(_ number: Int) -> String {
//        if number == 1 {
//            return String(localized: "Start")
//        }
//
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal

        return formatter.string(from: number as NSNumber)!.replacingOccurrences(of: ".", with: "")
    }
}

struct SettingsNumberEntryView: View {
    @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var numberEntryType: Int = 1
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    private var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @State private var price: Double = 0
    @State private var category: Category? = nil
    @State var isEditingDecimal = false
    @State var decimalValuesAssigned: AssignedDecimal = .none
    @State private var priceString: String = "0"

    private var disabled: Bool {
        price == 0.0
    }

    let options = ["Type 1", "Type 2"]

    @Namespace var animation

    var body: some View {
        VStack(spacing: 10) {
            Text("Number Entry Method")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }

            HStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { option in
                    Text(LocalizedStringKey(options[option]))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundColor(numberEntryType == (option + 1) ? Color.PrimaryText : Color.SubtitleText)
                        .padding(6)
                        .padding(.horizontal, 8)
                        .background {
                            if numberEntryType == (option + 1) {
                                Capsule()
                                    .fill(Color.SecondaryBackground)
                                    .matchedGeometryEffect(id: "TAB1", in: animation)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            DispatchQueue.main.async {
                                withAnimation(.easeIn(duration: 0.15)) {
                                    numberEntryType = (option + 1)
                                }
                            }
                        }
                }
            }
            .padding(3)
            .background(Capsule().fill(Color.PrimaryBackground).shadow(color: colorScheme == .light ? Color.Outline : Color.clear, radius: 6))
            .overlay(Capsule().stroke(colorScheme == .light ? Color.clear : Color.Outline.opacity(0.4), lineWidth: 1.3))
            .padding(25)

            VStack(spacing: 10) {
                if numberEntryType == 1 {
                    Text("\"Pre-dotted\"")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundColor(Color.PrimaryText)

                    Text("If you're too lazy to add a decimal point, I gotchu covered.")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.SubtitleText)
                } else {
                    Text("\"Cent-less\"")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundColor(Color.PrimaryText)

                    Text("If your transactions usually amount to whole numbers - this one is for you.")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.SubtitleText)
                }
            }
            .padding(.horizontal, 25)

            Spacer()

            NumberPadTextView(
                price: $price,
                isEditingDecimal: $isEditingDecimal,
                decimalValuesAssigned: $decimalValuesAssigned
            )

            Spacer()

            NumberPad(
                price: $price,
                category: $category,
                isEditingDecimal: $isEditingDecimal,
                decimalValuesAssigned: $decimalValuesAssigned
              ) {
              submit()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
    }

    func submit() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        price = 0
    }
}

struct SettingsNotificationsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @AppStorage("showNotifications", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showNotifications: Bool = false
    @AppStorage("notificationsEnabled", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var notificationsEnabled: Bool = true
    @State var option = 1
    @State var customTime = Date.now

    var center = UNUserNotificationCenter.current()

    @Namespace var animation

    var body: some View {
        VStack {
            Text("Notifications")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                HStack {
                    Text("Enable Notifications")
                        .font(.system(.body, design: .rounded))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(Color.PrimaryText)

                    Spacer()

                    ZStack(alignment: showNotifications ? .trailing : .leading) {
                        Capsule()
                            .frame(width: 42, height: 28)
                            .foregroundColor(showNotifications ? .green : .gray.opacity(0.8))

                        Circle()
                            .foregroundColor(Color.white)
                            .padding(2)
                            .frame(width: 28, height: 28)
                            .matchedGeometryEffect(id: "toggle", in: animation)
                    }
                    .onTapGesture {
                        if showNotifications {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                center.removeAllPendingNotificationRequests()
                                showNotifications.toggle()
                            }
                        } else {
                            center.getNotificationSettings { settings in
                                if settings.authorizationStatus == .notDetermined {
                                    center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                                        if success {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showNotifications.toggle()
                                                newNotification()
                                            }
                                        } else if let error = error {
                                            print(error.localizedDescription)
                                            notificationsEnabled = false
                                        }
                                    }
                                } else if settings.authorizationStatus == .denied {
                                    notificationsEnabled = false

                                    DispatchQueue.main.async {
                                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsURL)
                                        }
                                    }

                                } else {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showNotifications.toggle()
                                        if showNotifications {
                                            newNotification()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .padding(.horizontal, 15)
            .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
            .padding(.bottom, 20)

            if showNotifications {
                VStack(spacing: 0) {
                    HStack {
                        Text("Every morning (8:00 AM)")
                            .font(.system(.body, design: .rounded))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(Color.PrimaryText)

                        Spacer()

                        if option == 1 {
                            Image(systemName: "checkmark")
                                .font(.system(.subheadline, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 15))
                                .foregroundColor(.DarkIcon.opacity(0.6))
                                .matchedGeometryEffect(id: "tick", in: animation)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.15)) {
                            option = 1
                        }
                    }
                    .padding(.vertical, 9)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }

                    HStack {
                        Text("Every evening (8:00 PM)")
                            .font(.system(.body, design: .rounded))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(Color.PrimaryText)

                        Spacer()

                        if option == 2 {
                            Image(systemName: "checkmark")
                                .font(.system(.subheadline, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 15))
                                .foregroundColor(.DarkIcon.opacity(0.6))
                                .matchedGeometryEffect(id: "tick", in: animation)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.15)) {
                            option = 2
                        }
                    }
                    .padding(.vertical, 9)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }

                    HStack {
                        Text("Custom Time")
                            .font(.system(.body, design: .rounded))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(Color.PrimaryText)

                        Spacer()

                        if option == 3 {
                            DatePicker("Custom notification time", selection: $customTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()

                            Image(systemName: "checkmark")
                                .font(.system(.subheadline, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 15))
                                .foregroundColor(.DarkIcon.opacity(0.6))
                                .matchedGeometryEffect(id: "tick", in: animation)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.15)) {
                            option = 3
                        }
                    }
                    .padding(.vertical, 9)
                }
                .padding(.horizontal, 15)
                .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
                .onChange(of: option) { newValue in
                    UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(option, forKey: "notificationOption")

                    if newValue == 3 {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: customTime)

                        UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(components.hour!, forKey: "customHour")
                        UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(components.minute!, forKey: "customMinute")
                    }

                    newNotification()
                }
                .onChange(of: customTime) { _ in
                    let components = Calendar.current.dateComponents([.hour, .minute], from: customTime)

                    UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(components.hour!, forKey: "customHour")
                    UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(components.minute!, forKey: "customMinute")

                    newNotification()
                }
                .onAppear {
                    if UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "notificationOption") != nil {
                        option = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "notificationOption")
                    }

                    if UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "customHour") != nil && UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "customMinute") != nil {
                        var components = DateComponents()
                        components.hour = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "customHour")
                        components.minute = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "customMinute")
                        customTime = Calendar.current.date(from: components)!
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
    }
}

struct SettingsGoofyView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @AppStorage("confetti", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var confetti: Bool = false

//    @AppStorage("chromatic", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var chromatic: Bool = false

    @AppStorage("logViewLineGraph", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var lineGraph: Bool = false

    @AppStorage("budgetViewStyle", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var budgetRows: Bool = false

    @AppStorage("swapTimeLabel", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var swapTimeLabel: Bool = false

    @AppStorage("showTransactionRecommendations", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showRecommendations: Bool = false

    @Namespace var animation

    var body: some View {
        VStack(spacing: 10) {
            Text("Feature Lab")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 0) {
                    ToggleRow(text: "Celebrate Expenses", bool: $confetti, id: 1)

                    ToggleRow(text: "Show Line Graph", bool: $lineGraph, id: 2)

                    ToggleRow(text: "Budget Rows", bool: $budgetRows, id: 3)
                }
                .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

                Text("Experimental features - proceed with caution.")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .padding(.horizontal, 15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 30)

                ToggleRow(text: "Replace Time Label", bool: $swapTimeLabel, id: 4)
                    .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

                Text("Swaps the time label of each transaction with its category name. However, if you do not manually input a note for each transaction - in which case the note is the category name by default - duplicate text will appear.")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .padding(.horizontal, 15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 30)

                ToggleRow(text: "Show Note Suggestions", bool: $showRecommendations, id: 5)
                    .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

                Text("Displays transaction suggestions whilst you type in the 'Note' field of the new transaction page.")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .padding(.horizontal, 15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 30)
            }

//            ToggleRow(text: "Miles-Morales Effect", bool: $chromatic, id: 5)
//            .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
//
//            Text("Enables a chromatic abberation effect on the 'New Transaction' page when a future date is set.")
//                .font(.system(size: 12, weight: .medium, design: .rounded))
//                .foregroundColor(Color.SubtitleText)
//                .padding(.horizontal, 15)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
    }

    @ViewBuilder
    func ToggleRow(text: String, bool: Binding<Bool>, id: Int) -> some View {
        HStack {
            Text(text)
                .font(.system(.body, design: .rounded))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(Color.PrimaryText)

            Spacer()

            ZStack(alignment: bool.wrappedValue ? .trailing : .leading) {
                Capsule()
                    .frame(width: 42, height: 28)
                    .foregroundColor(bool.wrappedValue ? .green : .gray.opacity(0.8))

                Circle()
                    .foregroundColor(Color.white)
                    .padding(2)
                    .frame(width: 28, height: 28)
                    .matchedGeometryEffect(id: "toggle\(id)", in: animation)
            }
            .onTapGesture {
                withAnimation {
                    bool.wrappedValue.toggle()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .padding(.horizontal, 15)
    }
}

func newNotification() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

    let content = UNMutableNotificationContent()
    content.title = String(localized: "Keep the streak going!")
    content.subtitle = String(localized: "Remember to input your expenses today.")
    content.sound = UNNotificationSound.default

    // show this notification five seconds from now
    var components = DateComponents()
    var option = 1

    if UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "notificationOption") != nil {
        option = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "notificationOption")
    }

    if option == 1 {
        components.hour = 8
        components.minute = 0
    } else if option == 2 {
        components.hour = 20
        components.minute = 0
    } else {
        if UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "customHour") != nil, UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "customMinute") != nil {
            components.hour = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "customHour")
            components.minute = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "customMinute")
        } else {
            components.hour = 8
            components.minute = 0
        }
    }

    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

    // choose a random identifier
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    // add our notification request
    UNUserNotificationCenter.current().add(request)
}

struct SettingsCategoryView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
//        VStack(spacing: 5) {
//            Text("Categories")
//                .font(.system(size: 20, weight: .semibold, design: .rounded))
//                .foregroundColor(Color.PrimaryText)
//                .frame(maxWidth: .infinity)
//                .overlay(alignment: .leading) {
//                    Button {
//                        self.presentationMode.wrappedValue.dismiss()
//                    } label: {
//                        Circle()
//                            .fill(Color.SecondaryBackground)
//                            .frame(width: 30, height: 30)
//                            .overlay {
//                                Image(systemName: "chevron.left")
//                                    .font(.system(size: 16, weight: .semibold))
//                                    .foregroundColor(Color.SubtitleText)
//
//                            }
//                    }
//
//                }
//                .padding(.bottom, 20)
//
//
//            ReusableCategoryView()
//        }

        CategoryView(mode: .settings, income: false)
            .navigationBarBackButtonHidden(true)
            .navigationBarTitle("")
            .navigationBarHidden(true)
//        .padding(20)
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.PrimaryBackground)
    }
}

struct SettingsUpcomingView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showFuture: Bool = true

    @State private var showSoon: Bool = false
    @EnvironmentObject var dataController: DataController

    @Namespace var animation

    var body: some View {
        VStack(spacing: 10) {
            Text("Upcoming Logs")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                HStack {
                    Text("Display on Log Page")
                        .font(.system(.body, design: .rounded))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(Color.PrimaryText)

                    Spacer()

                    ZStack(alignment: showFuture ? .trailing : .leading) {
                        Capsule()
                            .frame(width: 42, height: 28)
                            .foregroundColor(showFuture ? .green : .gray.opacity(0.8))

                        Circle()
                            .foregroundColor(Color.white)
                            .padding(2)
                            .frame(width: 28, height: 28)
                            .matchedGeometryEffect(id: "toggle1", in: animation)
                    }
                    .onTapGesture {
                        showFuture.toggle()
                    }
                    .onChange(of: showFuture) { newValue in
                        UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(newValue, forKey: "showUpcomingTransactions")

                        if !newValue {
                            showSoon = false
                            UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(false, forKey: "showUpcomingTransactionsWhenUpcoming")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)

                HStack {
                    Text("Limit to 14-Day Outlook")
                        .font(.system(.body, design: .rounded))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(Color.PrimaryText)

                    Spacer()

                    ZStack(alignment: showSoon ? .trailing : .leading) {
                        Capsule()
                            .frame(width: 42, height: 28)
                            .foregroundColor(showSoon ? .green : .gray.opacity(0.8))

                        Circle()
                            .foregroundColor(Color.white)
                            .padding(2)
                            .frame(width: 28, height: 28)
                            .matchedGeometryEffect(id: "toggle2", in: animation)
                    }
                    .onTapGesture {
                        showSoon.toggle()
                    }
                    .onChange(of: showSoon) { newValue in
                        UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(newValue, forKey: "showUpcomingTransactionsWhenUpcoming")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .padding(.horizontal, 15)
            .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

            Text("Don't worry, even if you do hide them there, you will aways be able to find all upcoming transactions right here.")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 12, weight: .medium, design: .rounded))
                .multilineTextAlignment(.leading)
                .foregroundColor(Color.SubtitleText)
                .padding(.horizontal, 15)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(showsIndicators: false) {
                FutureListView(dataController: dataController, filterMode: false, limitedMode: false)
                    .padding(.bottom, 70)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
        .onAppear {
            showFuture = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.bool(forKey: "showUpcomingTransactions")
            showSoon = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.bool(forKey: "showUpcomingTransactionsWhenUpcoming")
        }
    }
}

struct SettingsEraseView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State var showAlert = false

    var body: some View {
        VStack(spacing: 10) {
            Text("Erase Data")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }
                .padding(.bottom, 20)

            Button {
                showAlert = true
            } label: {
                Text("Permanently Delete Everythin'")
                    .font(.system(.body, design: .rounded))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 15)
                    .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
            }

            Text("This action would delete all existing transactions, categories, and budgets, and cannot be undone.")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 12, weight: .medium, design: .rounded))
                .multilineTextAlignment(.leading)
                .foregroundColor(Color.SubtitleText)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
        .fullScreenCover(isPresented: $showAlert) {
            DeleteAllAlert()
        }
    }
}

struct DeleteAllAlert: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var systemColorScheme

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var bottomEdge: Double = 15

    @State private var offset: CGFloat = 0

    @GestureState var isDetectingLongPress = false
    @State var completedLongPress = false

    var longPress: some Gesture {
        LongPressGesture(minimumDuration: 2)
            .updating($isDetectingLongPress) { currentState, gestureState,
                _ in
                gestureState = currentState
            }
            .onEnded { finished in
                self.completedLongPress = finished
            }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }

            VStack(alignment: .leading, spacing: 1.5) {
                HStack(spacing: 7) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(.callout, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 14, weight: .medium, design: .rounded))

                    Text("Danger Zone")
                        .font(.system(.title2, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 20, weight: .medium, design: .rounded))
                }
                .foregroundColor(.PrimaryText)

                Text("This action genuinely cannot be undone. Long press to confirm.")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.SubtitleText)
                    .padding(.bottom, 15)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.AlertRed.opacity(0.23))
                            .frame(width: proxy.size.width)

                        Rectangle()
                            .fill(Color.AlertRed)
                            .frame(width: proxy.size.width, height: 100)
                            .offset(x: completedLongPress ? 0 : (isDetectingLongPress ? 0 : -(proxy.size.width)))
                            .animation(.easeInOut(duration: 2), value: isDetectingLongPress)

                        Text("Delete Literally Everything")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: proxy.size.width, alignment: .center)
                    }
                    .frame(height: proxy.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .frame(height: 45)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
                .gesture(
                    LongPressGesture(minimumDuration: 2)
                        .updating($isDetectingLongPress, body: { currentState, state, _ in
                            state = currentState
                        })
                        .onEnded { _ in
                            self.completedLongPress.toggle()
                        }
                )
                .onChange(of: completedLongPress) { _ in
                    if completedLongPress {
                        let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                        impactMed.impactOccurred()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dataController.deleteAll()

                            dismiss()
                        }
                    }
                }

                Button {
                    withAnimation(.easeOut(duration: 0.7)) {
                        dismiss()
                    }

                } label: {
                    Text("Back Out")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.PrimaryText.opacity(0.9))
                        .frame(height: 45)
                        .frame(maxWidth: .infinity)
//                        .background(Color("13").opacity(0.23), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }
            .padding(13)
//            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height < 0 {
                            offset = gesture.translation.height / 3
                        } else {
                            offset = gesture.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 20 {
                            dismiss()
                        } else {
                            withAnimation {
                                offset = 0
                            }
                        }
                    }
            )
//            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
//                .onEnded({ value in
//                    if value.translation.height > 0 {
//                        dismiss()
//                    }
//                }))
            .padding(.horizontal, 17)
            .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
        }
        .edgesIgnoringSafeArea(.all)
        .background(BackgroundBlurView())
    }
}

struct SettingsCloudView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var iCloudStorage: Bool = false
    @Namespace var animation

    var body: some View {
        VStack(spacing: 10) {
            Text("iCloud Sync")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        SettingsBackButton()
                    }
                }
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                HStack {
                    Text("Enable Sync")
                        .font(.system(.body, design: .rounded))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(Color.PrimaryText)

                    Spacer()

                    ZStack(alignment: iCloudStorage ? .trailing : .leading) {
                        Capsule()
                            .frame(width: 42, height: 28)
                            .foregroundColor(iCloudStorage ? .green : .gray.opacity(0.8))

                        Circle()
                            .foregroundColor(Color.white)
                            .padding(2)
                            .frame(width: 28, height: 28)
                            .matchedGeometryEffect(id: "toggle", in: animation)
                    }
                    .onTapGesture {
                        iCloudStorage.toggle()
                    }
                    .onChange(of: iCloudStorage) { newValue in
                        NSUbiquitousKeyValueStore.default.set(newValue, forKey: "icloud_sync")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .padding(.horizontal, 15)
            .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

            Text("Close and reload app for change to take effect.")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 12, weight: .medium, design: .rounded))
                .multilineTextAlignment(.leading)
                .foregroundColor(Color.SubtitleText)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
        .onAppear {
            iCloudStorage = NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync")
        }
    }
}

struct SettingsBackButton: View {
    var body: some View {
        Image(systemName: "chevron.left")
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundColor(Color.SubtitleText)
            .padding(8)
            .background(Color.SecondaryBackground, in: Circle())
    }
}
