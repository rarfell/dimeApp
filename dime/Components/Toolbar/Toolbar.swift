import SwiftUI

struct Toolbar<Content>: View where Content: View {
    var title: String?
    var rightButton: (() -> Content)?

    var body: some View {
        HStack(spacing: 8) {
//            BackButton(presentationMode: <#T##Binding<PresentationMode>#>)
            Spacer()
            if let title = title {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            Spacer()
            if let rightButton = rightButton {
                rightButton()
            }
        }
    }
}
