//
//  StepperButtons.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct StepperButtonView: View {
    let left: Bool
    let disabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: {
            self.action()
        }) {
            Image(systemName: left ? "chevron.left" : "chevron.right")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color.SubtitleText)
                .padding(8)
                .background(Color.SecondaryBackground, in: Circle())
                .opacity(disabled ? 0.3 : 1)
        }
    }
}
