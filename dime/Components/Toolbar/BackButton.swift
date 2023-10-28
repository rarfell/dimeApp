//
//  BackButton.swift
//  dime
//
//  Created by Yumi on 2023-10-24.
//

import SwiftUI

struct BackButton: View {
    var presentationMode: Binding<PresentationMode>

    var body: some View {
        Circle()
            .fill(Color.SecondaryBackground)
            .frame(width: 33, height: 33)
            .overlay {
                Image(systemName: "chevron.left")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .foregroundColor(Color.SubtitleText)
                    .offset(y: 0.8)
            }
            .onTapGesture {
                presentationMode.wrappedValue.dismiss()
            }
    }
}
