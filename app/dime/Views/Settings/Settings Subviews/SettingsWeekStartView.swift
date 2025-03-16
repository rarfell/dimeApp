//
//  SettingsWeekStartView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct SettingsWeekStartView: View {
  @AppStorage("firstWeekday", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var firstWeekday: Int = 1
  @AppStorage("firstDayOfMonth", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var firstDayOfMonth: Int = 1
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
        .foregroundColor(Color.SubtitleText)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)

      VStack(spacing: 0) {
        ForEach(options.indices, id: \.self) { option in
          HStack {
            Text(LocalizedStringKey(options[option]))
              .font(.system(.body, design: .rounded))
              .foregroundColor(Color.PrimaryText)

            Spacer()

            if firstWeekday == (option + 1) {
              Image(systemName: "checkmark")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
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

      Text("Start of Month")
        .font(.system(.body, design: .rounded).weight(.medium))
        .foregroundColor(Color.SubtitleText)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)

      ScrollView(showsIndicators: false) {
        ScrollViewReader { value in
          VStack(alignment: .leading, spacing: 0) {
            ForEach(1..<29) { day in

              HStack {
                Text("\(getOrdinal(day)) of month")
                  .font(.system(.body, design: .rounded))
                  .foregroundColor(Color.PrimaryText)

                Spacer()

                if firstDayOfMonth == day {
                  Image(systemName: "checkmark")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
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
        .foregroundColor(Color.SubtitleText)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 30)
    }
    .modifier(SettingsSubviewModifier())
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
