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
        ToolbarButton(systemName: "chevron.left") {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
