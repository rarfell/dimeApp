//
//  SuggestedTransactions.swift
//  dime
//
//  Created by Yumi on 2023-10-28.
//

import SwiftUI

struct SuggestedTransactions: View {
    @Binding var note: String
    @Binding var numbers: [Int]
    @Binding var numbers1: [String]
    @Binding var category: Category?
    @Binding var income: Bool
    var currencySymbol: String
    var suggestedTransactions: [Transaction]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestedTransactions, id: \.self) { transaction in
                    Button {
                        let string = String(format: "%.2f", transaction.wrappedAmount)
                        var stringArray = string.compactMap { String($0) }
                        note = transaction.wrappedNote

                        withAnimation {
                            numbers = stringArray.compactMap { Int($0) }
                            if round(transaction.wrappedAmount) == transaction.wrappedAmount {
                                stringArray.removeLast()
                                stringArray.removeLast()
                                stringArray.removeLast()
                                numbers1 = stringArray
                            } else {
                                numbers1 = stringArray
                            }
                            if category == nil {
                                category = transaction.category
                            }
                        }

                        self.hideKeyboard()
                    } label: {
                        HStack(spacing: 3) {
                            Text(transaction.wrappedNote)
                                .font(.system(size: 17.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.PrimaryText)
                                .lineLimit(1)
                                .padding(.vertical, 3.5)
                                .padding(.horizontal, 7)

                            Text("\(currencySymbol)\(Int(round(transaction.wrappedAmount)))")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .foregroundStyle(Color(hex: transaction.wrappedColour))
                                .padding(.vertical, 3.5)
                                .padding(.horizontal, 5)
                                .background(
                                    Color(hex: transaction.wrappedColour).opacity(0.23),
                                    in: RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                                )
                        }
                        .padding(5)
                        .background(
                            Color.SecondaryBackground,
                            in: RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                        )
                    }
                }
            }
        }
        .padding(.bottom, 5)
    }
}
