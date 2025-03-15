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

  @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var colourScheme: Int = 0
  var colourSchemeString: String {
    if colourScheme == 1 {
      return String(localized: "Light")
    } else if colourScheme == 2 {
      return String(localized: "Dark")
    } else {
      return String(localized: "System")
    }
  }

  @AppStorage("activeIcon", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var activeIcon: String = "AppIcon"
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

  @AppStorage("firstWeekday", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var firstWeekday: Int = 1
  var firstWeekdayString: String {
    if firstWeekday == 1 {
      return String(localized: "Sunday")
    } else {
      return String(localized: "Monday")
    }
  }

  @AppStorage("showNotifications", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var showNotifications: Bool = false
  @AppStorage("notificationOption", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var option: Int = 1
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
  let featureRequestEmail = SupportEmail(
    toAddress: "rafasohhh@gmail.com", subject: "Feature Request")

  @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var numberEntryType: Int = 2

  var numberEntryString: String {
    if numberEntryType == 1 {
      return String(localized: "Type 1")
    } else {
      return String(localized: "Type 2")
    }
  }

  @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var showCents: Bool = true

  @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated:
    Bool = true

  @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency:
    String = Locale.current.currencyCode!

  @AppStorage("incomeTracking", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var incomeTracking: Bool = true
    
  @AppStorage("showExpenseOrIncomeSign", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var showExpenseOrIncomeSign: Bool = true

  @AppStorage(
    "showUpcomingTransactions", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var showUpcoming: Bool = true

  var upcomingString: String {
    if showUpcoming {
      return String(localized: "Shown")
    } else {
      return String(localized: "Hidden")
    }
  }

    @AppStorage("haptics", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
    var hapticType: Int = 1

    var hapticString: String {
      if hapticType == 0 {
        return String(localized: "None")
      } else if hapticType == 1 {
        return String(localized: "Subtle")
      } else {
        return String(localized: "Excessive")
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

              //                            .font(.system(size: 12, weight: .semibold, design: .rounded))
              .foregroundColor(Color.SubtitleText)
              .padding(.horizontal, 10)
              .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 13) {

              NavigationLink(destination: SettingsNotificationsView()) {
                SettingsRowView(
                  systemImage: "bell.fill", title: "Notifications", colour: 102,
                  optionalText: notificationString)
              }

              NavigationLink(destination: SettingsCurrencyView()) {
                SettingsRowView(
                  systemImage: "coloncurrencysign.square.fill", title: "Currency", colour: 103,
                  optionalText: currency)
              }

              NavigationLink(
                destination: SettingsNumberEntryView()
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
                SettingsRowView(
                  systemImage: "keyboard.fill", title: "Number Entry", colour: 104,
                  optionalText: numberEntryString)
              }

              ToggleRow(
                icon: "faceid", color: "105", text: "Authentication",
                bool: appLockVM.isAppLockEnabled,
                onTap: {
                  appLockVM.appLockStateChange(appLockState: !appLockVM.isAppLockEnabled)
                })

              ToggleRow(
                icon: "banknote.fill", color: "106", text: "Income Tracking", bool: incomeTracking,
                onTap: {
                  incomeTracking.toggle()

                  if !incomeTracking {
                    UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
                      false, forKey: "insightsViewIncomeFiltering")
                    UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
                      3, forKey: "logInsightsType")
                  }
                })

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
            Text("APPEARANCE")
              .font(.system(.footnote, design: .rounded).weight(.semibold))

              //                            .font(.system(size: 12, weight: .semibold, design: .rounded))
              .foregroundColor(Color.SubtitleText)
              .padding(.horizontal, 10)
              .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 13) {
              NavigationLink(destination: SettingsAppearanceView()) {
                SettingsRowView(
                  systemImage: "circle.righthalf.filled", title: "Theme", colour: 100,
                  optionalText: colourSchemeString)
              }

              NavigationLink(destination: SettingsAppIconView()) {
                SettingsRowView(
                  systemImage: "app.badge.fill", title: "App Icon", colour: 101,
                  optionalText: appIconString)
              }

              ToggleRow(
                icon: "centsign.circle.fill", color: "107", text: "Display Cents", bool: showCents,
                onTap: {
                  showCents.toggle()
                })

              NavigationLink(destination: SettingsUpcomingView()) {
                SettingsRowView(
                  systemImage: "sun.min.fill", title: "Upcoming Logs", colour: 108,
                  optionalText: upcomingString)
              }
                
              ToggleRow(
                icon: "plusminus", color: "123", text: "Display +/- Symbol", bool: showExpenseOrIncomeSign,
                onTap: {
                    showExpenseOrIncomeSign.toggle()
                })

              ToggleRow(
                icon: "hare.fill", color: "121", text: "Animated Charts", bool: animated, smaller: true,
                onTap: {
                  animated.toggle()
                })

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

              //                            .font(.system(size: 12, weight: .semibold, design: .rounded))
              .foregroundColor(Color.SubtitleText)
              .padding(.horizontal, 10)
              .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 13) {
              NavigationLink(
                destination: SettingsCategoryView()
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
                SettingsRowView(
                  systemImage: "rectangle.grid.2x2.fill", title: "Categories", colour: 110)
              }

              NavigationLink(destination: SettingsCloudView()) {
                SettingsRowView(
                  systemImage: "icloud.fill", title: "iCloud Sync", colour: 111,
                  optionalText: iCloudString)
              }

              //
              //                            NavigationLink(destination: SettingsQuickAddWidgetView()) {
              //                                SettingsRowView(systemImage: "bolt.square.fill", title: "Quick-Add Widget", colour: 115)
              //                            }

              Button {
                showImportGuide = true
              } label: {
                SettingsRowView(
                  systemImage: "square.and.arrow.down.fill", title: "Import Data", colour: 112)
              }

              Button {
                exportData()
              } label: {
                SettingsRowView(
                  systemImage: "square.and.arrow.up.fill", title: "Export Data", colour: 113)
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

              //                            .font(.system(size: 12, weight: .semibold, design: .rounded))
              .foregroundColor(Color.SubtitleText)
              .padding(.horizontal, 10)
              .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 13) {

                NavigationLink(destination: SettingsHapticsView()) {
                  SettingsRowView(
                    systemImage: "hand.tap.fill", title: "Haptics", colour: 100,
                    optionalText: hapticString)
                }

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
                SettingsRowView(
                  systemImage: "hand.wave.fill", title: "Feature Request", colour: 125)
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
                SettingsRowView(
                  systemImage: "camera.fill", title: "Follow Rafael on X", colour: 129)
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

                //                                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color.SubtitleText)

              Text("·")
                .font(.system(.footnote, design: .rounded).weight(.medium))

                .foregroundColor(Color.SubtitleText)

              Text("What's New")
                .font(.system(.footnote, design: .rounded).weight(.medium))

                .foregroundColor(Color.PrimaryText)
                .onTapGesture {
                  showUpdate = true
                }
            }

            Text("Made with ❤️ by \(makeAttributedString()) from 🇸🇬")
              .font(.system(.footnote, design: .rounded).weight(.medium))

              .foregroundColor(Color.SubtitleText)
              .multilineTextAlignment(.center)
          }
          .padding(.horizontal, 25)
          .padding(.bottom, 95)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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
    func ToggleRow(icon: String, color: String, text: String, bool: Bool, smaller: Bool = false, onTap: @escaping () -> Void)
    -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
            .font(.system(smaller ? .subheadline : .body, design: .rounded))
        .foregroundColor(.white)
        .frame(
          width: dynamicTypeSize > .xLarge ? 40 : 30, height: dynamicTypeSize > .xLarge ? 40 : 30,
          alignment: .center
        )
        .background(Color(color), in: RoundedRectangle(cornerRadius: 6))

      Text(text)
        .font(.system(.body, design: .rounded).weight(.medium))
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
      windowScene.keyWindow?.rootViewController?.present(
        activityView, animated: true, completion: nil)
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

      csvText +=
        "\(transaction.wrappedDate),\(string),\(String(format: "%.2f", transaction.wrappedAmount)),\(transaction.category?.wrappedName ?? ""),\(type)\n"
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

  @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var bottomEdge: Double = 15

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
              //                            .font(.system(size: 18, weight: .medium, design: .rounded))
              .foregroundColor(Color.SubtitleText)
              .frame(maxWidth: .infinity)
              .frame(height: 200)
          }
        case .failed:
          Text("Unable to load tip options, please try again later 🥲")
            .font(.system(.body, design: .rounded).weight(.medium))

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

              //                                .font(.system(size: 16))
              Text("Tip Jar")
                .font(.system(.title2, design: .rounded).weight(.medium))

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

                  //                                    .font(.system(size: 14, weight: .semibold))
                  .foregroundColor(Color.SubtitleText)
                  .padding(7)
                  .background(Color.SecondaryBackground, in: Circle())
                  .contentShape(Circle())
              }
              .offset(x: 5, y: -5)
            }

            Text(
              "Hey! Dime was built by a solo student developer, and is intended to be completely free-of-charge, with no paywalls or ads. If you enjoy using Dime and want to support development, please consider a small tip."
            )
            .font(.system(.callout, design: .rounded).weight(.medium))

            //                            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.SubtitleText)
            .padding(.bottom, 20)

            ProductView(
              products: unlockManager.loadedProducts.sorted {
                $0.price.doubleValue < $1.price.doubleValue
              }
            )
            .padding(.bottom, 20)

            Text(bottomCaption)
              .font(.system(.subheadline, design: .rounded).weight(.medium))

              //                                .font(.system(size: 14, weight: .medium, design: .rounded))
              .frame(maxWidth: .infinity)
              .foregroundColor(.SubtitleText)
          }
        }
      }
      .padding(18)
      .animation(.easeInOut, value: unlockManager.failedTransaction)
      .background(
        RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(
          color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 13).stroke(
          systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3)
      )
      .offset(y: offset)
      .confettiCannon(
        counter: $counter, num: 50, openingAngle: Angle(degrees: 0),
        closingAngle: Angle(degrees: 360), radius: 200
      )
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
              .background(
                Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous)
              )
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

        //                .font(.system(size: 17))
        //                .padding(5)
        .foregroundColor(.white)
        .frame(
          width: dynamicTypeSize > .xLarge ? 40 : 30, height: dynamicTypeSize > .xLarge ? 40 : 30,
          alignment: .center
        )
        .background(Color("\(colour)"), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

      Text(LocalizedStringKey(title))
        .font(.system(.body, design: .rounded).weight(.medium))

        //                .font(.system(size: 17, weight: .medium, design: .rounded))
        .lineLimit(1)
        .foregroundColor(Color.PrimaryText)

      Spacer()

      if optionalText != nil {
        Text(optionalText!)
          .font(.system(.body, design: .rounded))

          //                    .font(.system(size: 17, weight: .regular, design: .rounded))
          .foregroundColor(.DarkIcon.opacity(0.6))
          .layoutPriority(1)
          .padding(.trailing, -8)
      }

      Image(systemName: "chevron.forward")
        .font(.system(.subheadline, design: .rounded))
        //                .font(.system(size: 15))
        .foregroundColor(.DarkIcon.opacity(0.6))
    }
    .frame(maxWidth: .infinity)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
  }
}

struct SettingsCategoryView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  var body: some View {
    CategoryView(mode: .settings, income: false)
      .navigationBarBackButtonHidden(true)
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .background(Color.PrimaryBackground)
  }
}
