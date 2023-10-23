//
//  SingleTransactionPhotoView.swift
//  dime
//
//  Created by Rafael Soh on 30/9/23.
//

import Foundation
import SwiftUI

struct SingleDayPhotoView: View {
    let amountText: String
    let dateText: String
    let transactions: [Transaction]
    let showCents: Bool
    let currencySymbol: String
    let currency: String
    let swapTimeLabel: Bool
    let future: Bool

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var colourScheme: Int = 0

    @Environment(\.colorScheme) var systemColorScheme

    var darkMode: Bool {
        (colourScheme == 0 && systemColorScheme == .dark) || colourScheme == 2
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 50) {
            VStack(spacing: 25) {
                VStack(spacing: 10) {
                    HStack {
                        Text(dateText)
                        Spacer()

                        Text(amountText)
                    }
                    .font(.system(size: 35, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.SubtitleText)

                    Line()
                        .stroke(Color.Outline, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                ForEach(transactions, id: \.id) { transaction in
                    SingleTransactionPhotoView(transaction: transaction, showCents: showCents, currencySymbol: currencySymbol, currency: currency, swapTimeLabel: swapTimeLabel, future: future)
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity)
            .background(Color.PrimaryBackground, in: RoundedRectangle(cornerRadius: 40))
            .shadow(color: Color.Outline, radius: 30)
//            .background(Color.neuBackground, in: RoundedRectangle(cornerRadius: 40))
//            .shadow(color: .dropShadow, radius: 45, x: 40, y: 40)
//            .shadow(color: .dropLight, radius: 45, x: -40, y: -40)
        }
        .padding(60)
        .background(Color.PrimaryBackground)
        .frame(width: 1100, alignment: .top)
    }
}

struct SingleTransactionPhotoView: View {
    let transaction: Transaction
    let showCents: Bool
    let currencySymbol: String
    let currency: String
    let swapTimeLabel: Bool
    let future: Bool

    var transactionAmountString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = currency

        if showCents {
            numberFormatter.maximumFractionDigits = 2
        } else {
            numberFormatter.maximumFractionDigits = 0
        }

        return numberFormatter.string(from: NSNumber(value: transaction.amount)) ?? "$0"
    }

    var body: some View {
        HStack(spacing: 25) {
            EmojiLogView(emoji: (transaction.category?.wrappedEmoji ?? ""),
                         colour: (transaction.category?.wrappedColour ?? "#FFFFFF"), future: future, huge: true)
                .frame(width: 100, height: 100, alignment: .center)
                .overlay(alignment: .bottomTrailing) {
                    if transaction.recurringType > 0 {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.DarkIcon)
                            .padding(3)
                            .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 6))
                            .offset(x: 5, y: 5)
                    }
                }

            VStack(alignment: .leading, spacing: 5.5) {
                Text(transaction.wrappedNote)
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                    .foregroundColor(future ? Color.SubtitleText : Color.PrimaryText)
                    .lineLimit(1)

                if future {
                    if transaction.wrappedDate > Date.now {
                        Text(dateFormatter(date: transaction.wrappedDate))
                            .font(.system(size: 35, weight: .medium, design: .rounded))
                            .foregroundColor(Color.EvenLighterText)
                            .lineLimit(1)
                    } else {
                        Text(dateFormatter(date: transaction.nextTransactionDate))
                            .font(.system(size: 35, weight: .medium, design: .rounded))
                            .foregroundColor(Color.EvenLighterText)
                            .lineLimit(1)
                    }

                } else {
                    if swapTimeLabel {
                        Text(transaction.wrappedCategoryName)
                            .font(.system(size: 35, weight: .medium, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                            .lineLimit(1)
                    } else {
                        Text(transaction.wrappedDate, format: .dateTime.hour().minute())
                            .font(.system(size: 35, weight: .medium, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if transaction.income {
                Text("+\(transactionAmountString)")
                    .font(.system(size: 45, weight: .medium, design: .rounded))
                    .foregroundColor(future ? Color.SubtitleText : Color.IncomeGreen)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .layoutPriority(1)
            } else {
                Text("-\(transactionAmountString)")
                    .font(.system(size: 45, weight: .medium, design: .rounded))
                    .foregroundColor(future ? Color.SubtitleText : Color.PrimaryText)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
//        .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 40))

        .frame(maxWidth: .infinity)
    }

    func dateFormatter(date: Date) -> String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "d MMM"
        return dateFormatter.string(from: date).uppercased()
    }
}
