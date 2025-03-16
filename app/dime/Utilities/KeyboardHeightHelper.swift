//
//  KeyboardHeightHelper.swift
//  xpenz
//
//  Created by Rafael Soh on 16/5/22.
//

import Combine
import Foundation
import SwiftUI
import UIKit

class KeyboardHeightHelper: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    private func listenForKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification,
                                               object: nil,
                                               queue: .main) { notification in
            guard let userInfo = notification.userInfo,
                  let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

            self.keyboardHeight = keyboardRect.height
        }

//        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification,
//                                               object: nil,
//                                               queue: .main) { (notification) in
//                                                self.keyboardHeight = 0
//        }
    }

    init() {
        listenForKeyboardNotifications()
    }
}

extension Publishers {
    // 1.
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        // 2.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }

        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        // 3.
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct KeyboardAwareModifier: ViewModifier {
    @AppStorage("keyboard", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var savedKeyboardHeight: Double = .init(UIScreen.main.bounds.height / 2.5)
    var showToolbar: Bool
//    @State private var keyboardHeight: CGFloat = 250

    private var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
                .map { $0.cgRectValue.height },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        ).eraseToAnyPublisher()
    }

    func body(content: Content) -> some View {
        content
            .frame(height: savedKeyboardHeight)
            .onReceive(keyboardHeightPublisher) { value in
                if value > 200 {
                    self.savedKeyboardHeight = value - 20
                }
            }
    }
}

extension View {
    func keyboardAwareHeight(showToolbar: Bool) -> some View {
        ModifiedContent(content: self, modifier: KeyboardAwareModifier(showToolbar: showToolbar))
    }
}
