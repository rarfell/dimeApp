//
//  SettingsUpcomingView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

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
            UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
              newValue, forKey: "showUpcomingTransactions")

            if !newValue {
              showSoon = false
              UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
                false, forKey: "showUpcomingTransactionsWhenUpcoming")
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)

        HStack {
          Text("Limit to 14-Day Outlook")
            .font(.system(.body, design: .rounded))
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
            UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(
              newValue, forKey: "showUpcomingTransactionsWhenUpcoming")
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
      }
      .padding(.horizontal, 15)
      .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

      Text(
        "Don't worry, even if you do hide them there, you will aways be able to find all upcoming transactions right here."
      )
      .font(.system(.caption, design: .rounded).weight(.medium))
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
    .modifier(SettingsSubviewModifier())
    .onAppear {
      showFuture = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.bool(
        forKey: "showUpcomingTransactions")
      showSoon = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.bool(
        forKey: "showUpcomingTransactionsWhenUpcoming")
    }
  }
}
