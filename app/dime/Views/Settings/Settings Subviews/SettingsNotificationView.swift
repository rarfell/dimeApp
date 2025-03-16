//
//  SettingsNotificationView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct SettingsNotificationsView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  @AppStorage("showNotifications", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var showNotifications: Bool = false
  @AppStorage("notificationsEnabled", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var notificationsEnabled: Bool = true
  @State var option = 1
  @State var customTime = Date.now

  var center = UNUserNotificationCenter.current()

  @Namespace var animation

  var body: some View {
    VStack {
      Text("Notifications")
        .font(.system(.title3, design: .rounded).weight(.semibold))
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
              .foregroundColor(Color.PrimaryText)

            Spacer()

            if option == 1 {
              Image(systemName: "checkmark")
                .font(.system(.subheadline, design: .rounded))
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
              .foregroundColor(Color.PrimaryText)

            Spacer()

            if option == 2 {
              Image(systemName: "checkmark")
                .font(.system(.subheadline, design: .rounded))
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
              .foregroundColor(Color.PrimaryText)

            Spacer()

            if option == 3 {
              DatePicker(
                "Custom notification time", selection: $customTime,
                displayedComponents: .hourAndMinute
              )
              .labelsHidden()

              Image(systemName: "checkmark")
                .font(.system(.subheadline, design: .rounded))
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
          UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
            option, forKey: "notificationOption")

          if newValue == 3 {
            let components = Calendar.current.dateComponents([.hour, .minute], from: customTime)

            UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
              components.hour!, forKey: "customHour")
            UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
              components.minute!, forKey: "customMinute")
          }

          newNotification()
        }
        .onChange(of: customTime) { _ in
          let components = Calendar.current.dateComponents([.hour, .minute], from: customTime)

          UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
            components.hour!, forKey: "customHour")
          UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
            components.minute!, forKey: "customMinute")

          newNotification()
        }
        .onAppear {
          if UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(
            forKey: "notificationOption") != nil {
            option = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(
              forKey: "notificationOption")
          }

          if UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "customHour")
            != nil
            && UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "customMinute")
              != nil {
            var components = DateComponents()
            components.hour = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(
              forKey: "customHour")
            components.minute = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(
              forKey: "customMinute")
            customTime = Calendar.current.date(from: components)!
          }
        }
      }
    }
    .modifier(SettingsSubviewModifier())
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

  if UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "notificationOption")
    != nil {
    option = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(
      forKey: "notificationOption")
  }

  if option == 1 {
    components.hour = 8
    components.minute = 0
  } else if option == 2 {
    components.hour = 20
    components.minute = 0
  } else {
    if UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "customHour") != nil,
      UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.object(forKey: "customMinute") != nil {
      components.hour = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(
        forKey: "customHour")
      components.minute = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(
        forKey: "customMinute")
    } else {
      components.hour = 8
      components.minute = 0
    }
  }

  let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

  // choose a random identifier
  let request = UNNotificationRequest(
    identifier: UUID().uuidString, content: content, trigger: trigger)

  // add our notification request
  UNUserNotificationCenter.current().add(request)
}
