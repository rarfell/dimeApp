//
//  SettingsAppIconView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct AppIconBundle: Hashable {
  let actualFileName: String
  let exampleFileName: String
  let displayName: String
  let displaySubtitle: String
}

struct SettingsAppIconView: View {
  @AppStorage("activeIcon", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var activeIcon: String = "AppIcon"
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  let options: [AppIconBundle] = [
    AppIconBundle(
      actualFileName: "AppIcon1", exampleFileName: "AppIcon1_EG", displayName: "V2.0",
      displaySubtitle: "Designed by the brilliant @rudra_dsigns, check out his work on Twitter."),
    AppIconBundle(
      actualFileName: "AppIcon2", exampleFileName: "AppIcon2_EG", displayName: "Unicorn",
      displaySubtitle: "Dime definitely isn't becoming one but it never hurts to keep dreaming."),
    AppIconBundle(
      actualFileName: "AppIcon3", exampleFileName: "AppIcon3_EG", displayName: "V1.5",
      displaySubtitle: "An early prototype also designed by @rudra_dsigns that I kinda fancy."),
    AppIconBundle(
      actualFileName: "AppIcon4", exampleFileName: "AppIcon4_EG", displayName: "O.G.",
      displaySubtitle: "Haphazardly put together in under 30 minutes, the original Dime icon.")
  ]

  @State private var position: Int?

  @Namespace var animation

  var body: some View {
    VStack(spacing: 10) {
      Text("App Icon")
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
                .foregroundColor(Color.PrimaryText)

              Text(options[index].displaySubtitle)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color.SubtitleText)
            }

            Spacer()

            if activeIcon == options[index].actualFileName {
              Image(systemName: "checkmark")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.DarkIcon.opacity(0.6))
                .matchedGeometryEffect(id: "tick", in: animation)
            } else {
              Image(systemName: "checkmark")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.SettingsBackground)
            }
          }
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
          .onTapGesture {
            withAnimation {
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
    }
    .modifier(SettingsSubviewModifier())
  }
}
