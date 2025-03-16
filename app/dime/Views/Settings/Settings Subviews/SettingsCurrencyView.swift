//
//  SettingsCurrencyView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct SettingsCurrencyView: View {
  @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var currencyCode: String = Locale.current.currencyCode!
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  let currencies = Currency.allCurrencies

  @Namespace var animation

  var body: some View {
    VStack(spacing: 10) {
      Text("Currencies")
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
        .padding(.bottom, 10)

      ScrollView(showsIndicators: false) {
        ScrollViewReader { value in
          VStack(spacing: 0) {
            ForEach(currencies, id: \.self) { currency in
              HStack(spacing: 10) {
                Text(currency.code)
                  .font(.system(.body, design: .rounded).weight(.semibold))
                  .foregroundColor(Color.SubtitleText)
                  .lineLimit(1)
                  //                                    .layoutPriority(1)
                  .frame(width: dynamicTypeSize > .xLarge ? 55 : 45, alignment: .leading)
                Text(currency.name)
                  .font(.system(.body, design: .rounded))
                  .foregroundColor(Color.PrimaryText)
                  .lineLimit(1)

                Spacer()

                if currency.code == currencyCode {
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
    .modifier(SettingsSubviewModifier())
  }
}
