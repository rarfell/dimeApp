//
//  SettingsAppearanceView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct SettingsAppearanceView: View {
  @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var colourScheme: Int = 0
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  let options = ["System", "Light", "Dark"]

  @Namespace var animation

  var body: some View {
    VStack(spacing: 10) {
      Text("Appearance")
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
        ForEach(options.indices, id: \.self) { option in
          HStack {
            Text(LocalizedStringKey(options[option]))
              .font(.system(.body, design: .rounded))
              .foregroundColor(Color.PrimaryText)

            Spacer()

            if colourScheme == option {
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
        .foregroundColor(Color.SubtitleText)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .modifier(SettingsSubviewModifier())
  }
}
