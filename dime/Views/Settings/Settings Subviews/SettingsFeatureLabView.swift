//
//  SettingsFeatureLabView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct SettingsGoofyView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  @AppStorage("confetti", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var confetti:
    Bool = false

  //    @AppStorage("chromatic", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var chromatic: Bool = false

  @AppStorage("logViewLineGraph", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var lineGraph: Bool = false

  @AppStorage("budgetViewStyle", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var budgetRows: Bool = false

  @AppStorage("swapTimeLabel", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var swapTimeLabel: Bool = false

  @AppStorage(
    "showTransactionRecommendations", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var showRecommendations: Bool = false

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

        Text(
          "Swaps the time label of each transaction with its category name. However, if you do not manually input a note for each transaction - in which case the note is the category name by default - duplicate text will appear."
        )
        .font(.system(.caption, design: .rounded).weight(.medium))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        //                    .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundColor(Color.SubtitleText)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 30)

        ToggleRow(text: "Show Note Suggestions", bool: $showRecommendations, id: 5)
          .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

        Text(
          "Displays transaction suggestions whilst you type in the 'Note' field of the new transaction page."
        )
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
    .modifier(SettingsSubviewModifier())
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
