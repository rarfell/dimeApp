//
//  SettingsNumberEntryView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct SettingsNumberEntryView: View {
  @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var numberEntryType: Int = 1
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @Environment(\.colorScheme) var colorScheme
  @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency:
    String = Locale.current.currencyCode!
  private var currencySymbol: String {
    return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
  }

  @State private var price: Double = 0
  @State private var category: Category?
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
            .foregroundColor(
              numberEntryType == (option + 1) ? Color.PrimaryText : Color.SubtitleText
            )
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
      .background(
        Capsule().fill(Color.PrimaryBackground).shadow(
          color: colorScheme == .light ? Color.Outline : Color.clear, radius: 6)
      )
      .overlay(
        Capsule().stroke(
          colorScheme == .light ? Color.clear : Color.Outline.opacity(0.4), lineWidth: 1.3)
      )
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
    .modifier(SettingsSubviewModifier())
  }

  func submit() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    price = 0
  }
}
