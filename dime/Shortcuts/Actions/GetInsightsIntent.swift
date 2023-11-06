//
//  GetInsightsIntent.swift
//  dime
//
//  Created by Rafael Soh on 5/8/23.
//

import AppIntents
import Foundation
import SwiftUI

@available(iOS 16.4, *)
struct GetInsightsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Insights"

    static var description =
        IntentDescription("Extracts your total expenditure or income for a particular time period")

    @Parameter(title: "Type", description: "Type of Data", requestValueDialog: IntentDialog("Which of the following would you like to extract?"))
    var type: ShortcutsInsightsType

    @Parameter(title: "Time Frame", description: "Time Frame of Data", requestValueDialog: IntentDialog("Over what time frame would you like to consider?"))
    var timeframe: ShortcutsInsightsTimeFrame

    @Parameter(title: "Category Filters", description: "Additional Category Filters", requestValueDialog: IntentDialog("Which additional category filters do you want to impose?"))
    var incomeCategories: [IncomeCategoryEntity]?

    @Parameter(title: "Category Filters", description: "Additional Category Filters", requestValueDialog: IntentDialog("Which additional category filters do you want to impose?"))
    var expenseCategories: [ExpenseCategoryEntity]?

    @MainActor
    func perform() async throws -> some ReturnsValue<Double> & ShowsSnippetView & ProvidesDialog {
        let dataController = DataController.shared
//        let dataController = DataController()

        let categories: [Category]
        let optionalIncome: Bool?
        let typeInt: Int

        switch type {
        case .net:
            categories = []
            optionalIncome = nil
            typeInt = 1
        case .income:
            if let unwrappedCategories = incomeCategories {
                categories = unwrappedCategories.compactMap { category in
                    try? dataController.findCategory(withId: category.id)
                }
            } else {
                categories = []
            }

            optionalIncome = true
            typeInt = 2
        case .spent:
            if let unwrappedCategories = expenseCategories {
                categories = unwrappedCategories.compactMap { category in
                    try? dataController.findCategory(withId: category.id)
                }
            } else {
                categories = []
            }
            optionalIncome = false
            typeInt = 3
        }

        let result = dataController.getShortcutInsights(type: typeInt, timeframe: timeframe.rawValue, optionalIncome: optionalIncome, categories: categories)

        return .result(value: result, dialog: "Here you go!") {
            ShortcutInsightsView(amount: result, type: type, timeframe: timeframe)
        }
    }

    static var parameterSummary: some ParameterSummary {
        Switch(\GetInsightsIntent.$type) {
            Case(ShortcutsInsightsType.net) {
                Summary("Calculate \(\.$type) for \(\.$timeframe)")
            }
            Case(ShortcutsInsightsType.income) {
                Summary("Calculate \(\.$type) for \(\.$timeframe)") {
                    \.$incomeCategories
                }
            }
            Case(ShortcutsInsightsType.spent) {
                Summary("Calculate \(\.$type) for \(\.$timeframe)") {
                    \.$expenseCategories
                }
            }
            DefaultCase {
                Summary("Calculate \(\.$type) for \(\.$timeframe)")
            }
        }
    }
}

enum ShortcutsInsightsTimeFrame: Int {
    case day = 1
    case week = 2
    case month = 3
    case year = 4
    case all = 5
}

@available(iOS 16, *)
extension ShortcutsInsightsTimeFrame: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(name: "Time Frame")
    }

    static var caseDisplayRepresentations: [ShortcutsInsightsTimeFrame: DisplayRepresentation] = [
        .day: DisplayRepresentation(title: "today"),
        .week: DisplayRepresentation(title: "this week"),
        .month: DisplayRepresentation(title: "this month"),
        .year: DisplayRepresentation(title: "this year"),
        .all: DisplayRepresentation(title: "all time")
    ]
}

enum ShortcutsInsightsType: String {
    case net, income, spent
}

@available(iOS 16, *)
extension ShortcutsInsightsType: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(name: "Insights Type")
    }

    static var caseDisplayRepresentations: [ShortcutsInsightsType: DisplayRepresentation] = [
        .net: DisplayRepresentation(title: "net total"),
        .income: DisplayRepresentation(title: "total income"),
        .spent: DisplayRepresentation(title: "total expenditure")
    ]
}

struct ShortcutInsightsView: View {
    let amount: Double
    let type: ShortcutsInsightsType
    let timeframe: ShortcutsInsightsTimeFrame

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!

    var leftText: String {
        switch type {
        case .net:
            return "Net total"
        case .income:
            return "Earned"
        case .spent:
            return "Spent"
        }
    }

    var rightText: String {
        switch timeframe {
        case .day:
            return "today"
        case .week:
            return "this week"
        case .month:
            return "this month"
        case .year:
            return "this year"
        case .all:
            return "all time"
        }
    }

    var amountString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = currency

        if showCents {
            numberFormatter.maximumFractionDigits = 2
        } else {
            numberFormatter.maximumFractionDigits = 0
        }

        return numberFormatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(leftText + " " + rightText)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(Color.SubtitleText)

            Text(amountString)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
        .padding(20)
    }
}
