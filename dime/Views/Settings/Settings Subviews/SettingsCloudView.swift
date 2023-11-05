//
//  SettingsCloudView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

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
        .multilineTextAlignment(.leading)
        .foregroundColor(Color.SubtitleText)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .onAppear {
      iCloudStorage = NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync")
    }
    .modifier(SettingsSubviewModifier())

  }
}
