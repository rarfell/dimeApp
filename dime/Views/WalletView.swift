//
//  WalletView.swift
//  dime
//
//  Created by Yumi on 2023-10-23.
//

import SwiftUI
import Combine
import CoreData

struct WalletView: View {
    var body: some View {
        VStack {
            WalletListView()
        }
    }
}

struct WalletListView: View {
    
    var body: some View {
        VStack (spacing: 5) {
            HStack {
                
            }
            List {
                HStack(spacing: 10) {
                    Text("🪪")
                        .font(.system(.subheadline, design: .rounded))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    Text("Wallet 1")
                        .font(.system(.body, design: .rounded))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .lineLimit(1)
                }
                .padding(.vertical, 5)
                .listRowBackground(Color.SettingsBackground)
                .listRowSeparatorTint(Color.Outline)
                .contentShape(Rectangle())
            }
        }
    }
}

#Preview {
    WalletView()
}
