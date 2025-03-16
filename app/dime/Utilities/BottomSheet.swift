//
//  BottomSheet.swift
//  dime
//
//  Created by Rafael Soh on 1/7/23.
//

import SwiftUI
import UIKit

// 1 - Create a UISheetPresentationController that can be used in a SwiftUI interface
struct SheetPresentationForSwiftUI<Content>: UIViewRepresentable where Content: View {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let detents: [UISheetPresentationController.Detent]
    let content: Content

    init(
        _ isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        detents: [UISheetPresentationController.Detent] = [.medium()],
        @ViewBuilder content: () -> Content
    ) {
        _isPresented = isPresented
        self.onDismiss = onDismiss
        self.detents = detents
        self.content = content()
    }

    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Create the UIViewController that will be presented by the UIButton
        let viewController = UIViewController()

        // Create the UIHostingController that will embed the SwiftUI View
        let hostingController = UIHostingController(rootView: content)

        // Add the UIHostingController to the UIViewController
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)

        // Set constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.leftAnchor.constraint(equalTo: viewController.view.leftAnchor).isActive = true
        hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor).isActive = true
        hostingController.view.rightAnchor.constraint(equalTo: viewController.view.rightAnchor).isActive = true
        hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor).isActive = true
        hostingController.didMove(toParent: viewController)

        // Set the presentationController as a UISheetPresentationController
        if let sheetController = viewController.presentationController as? UISheetPresentationController {
            sheetController.detents = detents
            sheetController.prefersGrabberVisible = true
            sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
            sheetController.largestUndimmedDetentIdentifier = .medium
        }

        // Set the coordinator (delegate)
        // We need the delegate to use the presentationControllerDidDismiss function
        viewController.presentationController?.delegate = context.coordinator

        if isPresented {
            // Present the viewController
            uiView.window?.rootViewController?.present(viewController, animated: true)
        } else {
            // Dismiss the viewController
            uiView.window?.rootViewController?.dismiss(animated: true)
        }
    }

    /* Creates the custom instance that you use to communicate changes
     from your view controller to other parts of your SwiftUI interface.
      */
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onDismiss: onDismiss)
    }

    class Coordinator: NSObject, UISheetPresentationControllerDelegate {
        @Binding var isPresented: Bool
        let onDismiss: (() -> Void)?

        init(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
            _isPresented = isPresented
            self.onDismiss = onDismiss
        }

        func presentationControllerDidDismiss(_: UIPresentationController) {
            isPresented = false
            if let onDismiss = onDismiss {
                onDismiss()
            }
        }
    }
}

// 2 - Create the SwiftUI modifier conforming to the ViewModifier protocol
struct SheetWithDetentsViewModifier<SwiftUIContent>: ViewModifier where SwiftUIContent: View {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let detents: [UISheetPresentationController.Detent]
    let swiftUIContent: SwiftUIContent

    init(isPresented: Binding<Bool>, detents: [UISheetPresentationController.Detent] = [.medium()], onDismiss: (() -> Void)? = nil, content: () -> SwiftUIContent) {
        _isPresented = isPresented
        self.onDismiss = onDismiss
        swiftUIContent = content()
        self.detents = detents
    }

    func body(content: Content) -> some View {
        ZStack {
            SheetPresentationForSwiftUI($isPresented, onDismiss: onDismiss, detents: detents) {
                swiftUIContent
            }.fixedSize()
            content
        }
    }
}

// 3 - Create extension on View that makes it easier to use the custom modifier
extension View {
    func sheetWithDetents<Content>(
        isPresented: Binding<Bool>,
        detents: [UISheetPresentationController.Detent],
        onDismiss: (() -> Void)?,
        content: @escaping () -> Content
    ) -> some View where Content: View {
        modifier(
            SheetWithDetentsViewModifier(
                isPresented: isPresented,
                detents: detents,
                onDismiss: onDismiss,
                content: content
            )
        )
    }
}
