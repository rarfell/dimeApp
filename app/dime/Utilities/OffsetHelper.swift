//
//  OffsetHelper.swift
//  dime
//
//  Created by Rafael Soh on 9/7/23.
//

import Combine
import Foundation
import SwiftUI

struct OffsetKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension View {
    @ViewBuilder
    func offsetExtractor(coordinateSpace _: String, completion: @escaping (CGRect) -> Void) -> some View {
        overlay(alignment: .top) {
            GeometryReader {
                let rect = $0.frame(in: .global)
                Color.clear
                    .preference(key: OffsetKey.self, value: rect)
                    .onPreferenceChange(OffsetKey.self, perform: completion)
            }
        }
    }
}

//
// class ScrollViewModel: NSObject, ObservableObject, UIGestureRecognizerDelegate {
//    let gestureID: String = UUID().uuidString
//    let gestureEnded = PassthroughSubject<Void, Never>()
//
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
//
//    func addGesture() {
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onGestureChange(gesture: )))
//        panGesture.delegate = self
//        panGesture.name = gestureID
//        rootController().view.addGestureRecognizer(panGesture)
//        print("ADDEEDDDD")
//    }
//
//    func removeGesture() {
//        rootController().view.gestureRecognizers?.removeAll(where: { gesture in
//            gesture.name == gestureID
//        })
//    }
//
//    func rootController() -> UIViewController {
//        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
//            return .init()
//        }
//
//        guard let root = screen.windows.first?.rootViewController else {
//            return .init()
//        }
//
//        return root
//    }
//
//    @objc
//    func onGestureChange(gesture: UIPanGestureRecognizer) {
//        if gesture.state == .cancelled || gesture.state == .ended {
//
//            gestureEnded.send()
//
//        }
//    }
//
// }
