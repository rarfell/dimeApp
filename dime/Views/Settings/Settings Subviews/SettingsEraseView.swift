//
//  SettingsEraseView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct SettingsEraseView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  @State var showAlert = false

  var body: some View {
    VStack(spacing: 10) {
      Text("Erase Data")
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

      Button {
        showAlert = true
      } label: {
        Text("Permanently Delete Everythin'")
          .font(.system(.body, design: .rounded))
          .foregroundColor(Color.PrimaryText)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 12)
          .padding(.horizontal, 15)
          .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))
      }

      Text(
        "This action would delete all existing transactions, categories, and budgets, and cannot be undone."
      )
      .font(.system(.caption, design: .rounded).weight(.medium))
      .multilineTextAlignment(.leading)
      .foregroundColor(Color.SubtitleText)
      .padding(.horizontal, 15)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .modifier(SettingsSubviewModifier())
    .fullScreenCover(isPresented: $showAlert) {
      DeleteAllAlert()
    }
  }
}

struct DeleteAllAlert: View {
  @EnvironmentObject var dataController: DataController
  @Environment(\.dismiss) var dismiss
  @Environment(\.colorScheme) var systemColorScheme

  @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
  var bottomEdge: Double = 15

  @State private var offset: CGFloat = 0

  @GestureState var isDetectingLongPress = false
  @State var completedLongPress = false

  var longPress: some Gesture {
    LongPressGesture(minimumDuration: 2)
      .updating($isDetectingLongPress) {
        currentState, gestureState,
        _ in
        gestureState = currentState
      }
      .onEnded { finished in
        self.completedLongPress = finished
      }
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.clear
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
          dismiss()
        }

      VStack(alignment: .leading, spacing: 1.5) {
        HStack(spacing: 7) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(.callout, design: .rounded).weight(.medium))

          Text("Danger Zone")
            .font(.system(.title2, design: .rounded).weight(.medium))
        }
        .foregroundColor(.PrimaryText)

        Text("This action genuinely cannot be undone. Long press to confirm.")
          .font(.system(.title3, design: .rounded).weight(.medium))
          .foregroundColor(.SubtitleText)
          .padding(.bottom, 15)

        GeometryReader { proxy in
          ZStack(alignment: .leading) {
            Rectangle()
              .fill(Color.AlertRed.opacity(0.23))
              .frame(width: proxy.size.width)

            Rectangle()
              .fill(Color.AlertRed)
              .frame(width: proxy.size.width, height: 100)
              .offset(x: completedLongPress ? 0 : (isDetectingLongPress ? 0 : -(proxy.size.width)))
              .animation(.easeInOut(duration: 2), value: isDetectingLongPress)

            Text("Delete Literally Everything")
              .font(.system(.title3, design: .rounded).weight(.semibold))
              .foregroundColor(.white)
              .frame(width: proxy.size.width, alignment: .center)
          }
          .frame(height: proxy.size.height)
          .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .frame(height: 45)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
        .gesture(
          LongPressGesture(minimumDuration: 2)
            .updating(
              $isDetectingLongPress,
              body: { currentState, state, _ in
                state = currentState
              }
            )
            .onEnded { _ in
              self.completedLongPress.toggle()
            }
        )
        .onChange(of: completedLongPress) { _ in
          if completedLongPress {
            let impactMed = UIImpactFeedbackGenerator(style: .heavy)
            impactMed.impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              dataController.deleteAll()

              dismiss()
            }
          }
        }

        Button {
          withAnimation(.easeOut(duration: 0.7)) {
            dismiss()
          }

        } label: {
            DeleteButton(text: "Back Out", red: false)
        }
      }
      .padding(13)
      .background(
        RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(
          color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 13).stroke(
          systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3)
      )
      .offset(y: offset)
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
            if value.translation.height > 20 {
              dismiss()
            } else {
              withAnimation {
                offset = 0
              }
            }
          }
      )
      .padding(.horizontal, 17)
      .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
    }
    .edgesIgnoringSafeArea(.all)
    .background(BackgroundBlurView())
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
  }
}
