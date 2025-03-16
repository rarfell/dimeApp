//
//  TestDragToAdd.swift
//  dime
//
//  Created by Rafael Soh on 15/10/23.
//

import SwiftUI

// Usage:
/*
 CustomRefreshView(showsIndicator: false) {
     # Add content here that should be pulled down
 } onRefresh: {
     # Do something here, i.e. refresh or open something
     # It's possible to add a waiting state: try? await Task.sleep(nanoseconds: 1000000000)
 }
 */

struct CustomRefreshView<Content: View>: View {
    var content: Content
    var showsIndicator: Bool
    var onRefresh: () async -> Void

    init(showsIndicator: Bool = false, @ViewBuilder content: @escaping () -> Content, onRefresh: @escaping () async -> Void) {
        self.showsIndicator = showsIndicator
        self.content = content()
        self.onRefresh = onRefresh
    }

    @StateObject var scrollDelegate: ScrollViewModel = .init()

    var body: some View {
        ScrollView(.vertical, showsIndicators: showsIndicator) {
            VStack(spacing: 0) {
                GeometryReader { _ in
                    HStack {
                        // Keep it centered
                        Spacer()
                        CustomProgressView(progress: scrollDelegate.progress)
                            .opacity(scrollDelegate.isEligible ? 0 : 1)
                        Spacer()
                    }
                    .opacity(scrollDelegate.isEligible ? 0 : 1)
                    .animation(.easeInOut(duration: 0.25), value: scrollDelegate.isEligible)
                    .frame(height: 200)
                    .opacity(scrollDelegate.progress)
                    .offset(y: scrollDelegate.isEligible ? -(scrollDelegate.contentOffset < 0 ? 0 : scrollDelegate.contentOffset) : -(scrollDelegate.scrollOffset < 0 ? 0 : scrollDelegate.scrollOffset))
                }
                .frame(height: 0)
                .offset(y: -75 + (75 * scrollDelegate.progress))

                content
                    .offset(coordinateSpace: "SCROLL") { offset in
                        scrollDelegate.contentOffset = offset

                        // Checking if refresh action should be triggered
                        if !scrollDelegate.isEligible {
                            var progress = offset / 100
                            progress = (progress < 0 ? 0 : progress)
                            progress = (progress > 1 ? 1 : progress)
                            scrollDelegate.scrollOffset = offset
                            scrollDelegate.progress = progress
                            print(progress)
                        }

                        // Additional haptic feedback at "success"
                        if scrollDelegate.isEligible && !scrollDelegate.isRefreshing {
                            scrollDelegate.isRefreshing = true
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        } else {}
                    }
            }
        }
        .coordinateSpace(name: "SCROLL")
        .onAppear(perform: scrollDelegate.addGesture)
        .onDisappear(perform: scrollDelegate.removeGesture)
        .onChange(of: scrollDelegate.isRefreshing) { _ in
            if scrollDelegate.isRefreshing {
//                scrollDelegate.vibrateAt25 = false
//                scrollDelegate.vibrateAt50 = false
//                scrollDelegate.vibrateAt75 = false
                Task {
                    // Trigger refresh action
                    await onRefresh()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scrollDelegate.progress = 0
                        scrollDelegate.isEligible = false
                        scrollDelegate.isRefreshing = false
                        scrollDelegate.scrollOffset = 0
                    }
                }
            }
        }
    }
}

// Previews if needed
struct CustomRefreshView_Previews: PreviewProvider {
    static var previews: some View {
        CustomRefreshView(showsIndicator: false) {
            Rectangle()
                .fill(Color.red)
                .frame(width: 200, height: 200)
        } onRefresh: {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}

class ScrollViewModel: NSObject, ObservableObject, UIGestureRecognizerDelegate {
    // MARK: Properties

    @Published var isEligible: Bool = false
    @Published var isRefreshing: Bool = false

    // MARK: Gesture Properties

    @Published var scrollOffset: CGFloat = 0
    @Published var contentOffset: CGFloat = 0
    @Published var progress: CGFloat = 0
    let gestureID: String = UUID().uuidString

    // MARK: Haptic Feedback Properties

//    @Published var vibrateAt25: Bool = false
//    @Published var vibrateAt50: Bool = false
//    @Published var vibrateAt75: Bool = false

    // Adding Pan Gesture To UI Main Application Window
    // With Simultaneous Gesture Desture
    // Thus it Wont disturb SwiftUI Scroll's And Gesture's
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: Adding Gesture

    func addGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onGestureChange(gesture:)))
        panGesture.delegate = self
        panGesture.name = gestureID
        rootController().view.addGestureRecognizer(panGesture)
    }

    // MARK: Removing When Leaving The View

    func removeGesture() {
        rootController().view.gestureRecognizers?.removeAll(where: { gesture in
            gesture.name == gestureID
        })
    }

    // MARK: Finding Root Controller

    func rootController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }

        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }

        return root
    }

    @objc
    func onGestureChange(gesture: UIPanGestureRecognizer) {
        if gesture.state == .cancelled || gesture.state == .ended {
            // User released touch here
            if !isRefreshing {
                if scrollOffset > 100 {
                    isEligible = true
                } else {
                    isEligible = false
                }
            }
        }
    }
}

// Extension to observe changes in the offset of a view
extension View {
    @ViewBuilder
    func offset(coordinateSpace: String, offset: @escaping (CGFloat) -> Void) -> some View {
        overlay {
            GeometryReader { proxy in
                let minY = proxy.frame(in: .named(coordinateSpace)).minY
                Color.clear
                    .preference(key: RefreshOffsetKey.self, value: minY)
                    .onPreferenceChange(RefreshOffsetKey.self) { value in
                        offset(value)
                    }
            }
        }
    }
}

// A preference key used to store the minimum Y offset of a view
struct RefreshOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Your custom view that is shown when the user pulls down. Gets a progress value from 0 to 1.
struct CustomProgressView: View {
    var progress: CGFloat
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(.clear.opacity(0.2), lineWidth: 5)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.Outline, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 50, height: 50)
                    .shadow(color: Color(red: 0.48, green: 0.57, blue: 1).opacity(0.4), radius: 4, x: 0, y: 3)

                // V1 with simple plus
                /*  Image(systemName: "plus")
                 .font(.system(size: 16 * (0.6 + progress), weight: .semibold))
                 .foregroundColor(.accentColorPrimary).opacity((0.3 + progress) > 1 ? 1 : (0.3 + progress)) */

                // Var 2: Filled
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32 * (0.6 + progress)))
                    .foregroundColor(Color.Outline).opacity((0.6 + progress) > 1 ? 1 : (0.6 + progress))
            }
            Text("Pull to add update")
        }
    }
}
