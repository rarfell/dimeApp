//
//  NewTransactionIntent.swift
//  dime
//
//  Created by Rafael Soh on 23/7/23.
//

import AppIntents
import Foundation
import SwiftUI

@available(iOS 16.4, *)
struct NewTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "New Transaction"

    static var description =
        IntentDescription("Log new transactions in a blink")

    @Parameter(title: "Type", description: "Type of the transaction", requestValueDialog: IntentDialog("Would you like to log an income or expense?"))
    var income: TransactionType

    @Parameter(title: "Amount", description: "Value of the transaction", controlStyle: .field, inclusiveRange: (lowerBound: 0.01, upperBound: 100_000_000), requestValueDialog: IntentDialog("How much was transacted?"))
    var amount: Double

    @Parameter(title: "Category", description: "Category associated with the transaction", requestValueDialog: IntentDialog("What category does it come under?"))
    var incomeCategory: IncomeCategoryEntity?

    @Parameter(title: "Category", description: "Category associated with the transaction", requestValueDialog: IntentDialog("What category does it come under?"))
    var expenseCategory: ExpenseCategoryEntity?

    @Parameter(title: "Note")
    var note: String?

    @Parameter(title: "Recurring Transaction", default: false)
    var recurringTransaction: Bool

    @Parameter(title: "Recurring Frequency", default: .weekly)
    var recurringType: RepeatType

//    struct CategoryOptionsProvider: DynamicOptionsProvider {
//
//        func results() async throws -> ItemCollection<CategoryEntity> {
//            let dataController = DataController()
//
//            let categories = dataController.getAllCategories().map { CategoryEntity(id: $0.id!, name: $0.wrappedName, emoji: $0.wrappedEmoji, income: $0.income)
//            }
//
//            let incomeCategories = categories.filter { $0.income }
//            let expenseCategories = categories.filter { !$0.income }
//
//            return ItemCollection {
//                ItemSection(
//                    "Income Categories",
//                    items: incomeCategories.map {
//                        IntentItem<CategoryEntity>.init($0)
//                    }
//                )
//                ItemSection(
//                    "Expense Categories",
//                    items: expenseCategories.map {
//                        IntentItem<CategoryEntity>.init($0)
//                    }
//                )
//
//            }
//        }
//    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        if expenseCategory == nil && incomeCategory == nil {
            if income == .expense {
                throw $expenseCategory.needsValueError()
            } else {
                throw $incomeCategory.needsValueError()
            }
        } else {
            if amount == 0 {
                throw $amount.needsValueError()
            }

            let dataController = DataController.shared
            let repeatType: Int

            if !recurringTransaction {
                repeatType = 0
            } else {
                switch recurringType {
                case .daily:
                    repeatType = 1
                case .weekly:
                    repeatType = 2
                case .monthly:
                    repeatType = 3
                }
            }

            if income == .expense {
                if let unwrappedExpenseCategory = expenseCategory {
                    let category = try dataController.findCategory(withId: unwrappedExpenseCategory.id)

                    let transaction = dataController.newTransaction(note: note ?? "", category: category, income: false, amount: amount, date: Date.now, repeatType: repeatType, repeatCoefficient: 1, delay: false)

                    return .result(dialog: "Expense successfully logged.") {
                        ShortcutTransactionView(transaction: transaction)
                    }
                } else {
                    throw $expenseCategory.needsValueError()
                }
            } else {
                if let unwrappedIncomeCategory = incomeCategory {
                    let category = try dataController.findCategory(withId: unwrappedIncomeCategory.id)

                    let transaction = dataController.newTransaction(note: note ?? "", category: category, income: true, amount: amount, date: Date.now, repeatType: repeatType, repeatCoefficient: 1, delay: false)

                    return .result(dialog: "Income successfully logged.") {
                        ShortcutTransactionView(transaction: transaction)
                    }
                } else {
                    throw $incomeCategory.needsValueError()
                }
            }
        }
    }

    static var parameterSummary: some ParameterSummary {
        Switch(\NewTransactionIntent.$income) {
            Case(TransactionType.expense) {
                When(\NewTransactionIntent.$recurringTransaction, .equalTo, true, {
                    Summary("Log an \(\.$income) of \(\.$amount) under \(\.$expenseCategory)") {
                        \.$note
                        \.$recurringTransaction
                        \.$recurringType
                    }
                }, otherwise: {
                    Summary("Log an \(\.$income) of \(\.$amount) under \(\.$expenseCategory)") {
                        \.$note
                        \.$recurringTransaction
                    }
                })
            }
            Case(TransactionType.income) {
                When(\NewTransactionIntent.$recurringTransaction, .equalTo, true, {
                    Summary("Log an \(\.$income) of \(\.$amount) under \(\.$incomeCategory)") {
                        \.$note
                        \.$recurringTransaction
                        \.$recurringType
                    }
                }, otherwise: {
                    Summary("Log an \(\.$income) of \(\.$amount) under \(\.$incomeCategory)") {
                        \.$note
                        \.$recurringTransaction
                    }
                })
            }
            DefaultCase {
                Summary("Log an \(\.$income) of \(\.$amount)") {
                    \.$note
                }
            }
        }
    }
}

// income or expense

enum TransactionType: String {
    case income, expense
}

@available(iOS 16, *)
extension TransactionType: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(name: "Type")
    }

    static var caseDisplayRepresentations: [TransactionType: DisplayRepresentation] = [
        .income: DisplayRepresentation(title: "income",
                                       image: .init(systemName: "plus.square.fill")),
        .expense: DisplayRepresentation(title: "expense",
                                        image: .init(systemName: "minus.square.fill"))
    ]
}

enum RepeatType: String {
    case daily, weekly, monthly
}

@available(iOS 16, *)
extension RepeatType: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(name: "Frequency")
    }

    static var caseDisplayRepresentations: [RepeatType: DisplayRepresentation] = [
        .daily: DisplayRepresentation(title: "Daily"),
        .weekly: DisplayRepresentation(title: "Weekly"),
        .monthly: DisplayRepresentation(title: "Monthly")
    ]
}

struct ShortcutTransactionView: View {
    let transaction: Transaction

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!

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
        HStack(spacing: 12) {
            EmojiLogView(emoji: (transaction.category?.wrappedEmoji ?? ""),
                         colour: (transaction.category?.wrappedColour ?? ""), future: false)
                .frame(width: 35, height: 35, alignment: .center)
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

            VStack(alignment: .leading) {
                Text(transaction.wrappedNote)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
                    .lineLimit(1)

                Text(transaction.wrappedDate, format: .dateTime.hour().minute())
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .lineLimit(1)
            }
            Spacer()
            if transaction.income {
                Text("+\(transactionAmountString)")
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundColor(Color.IncomeGreen)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .layoutPriority(1)
            } else {
                Text("-\(transactionAmountString)")
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
    }
}
