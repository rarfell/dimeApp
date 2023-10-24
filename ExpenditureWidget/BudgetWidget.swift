//
//  BudgetWidget.swift
//  dime
//
//  Created by Rafael Soh on 17/8/22.
//

import SwiftUI
import WidgetKit

struct BudgetWidget: Widget {
    let kind: String = "BudgetWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: BudgetWidgetConfigurationIntent.self, provider: BudgetWidgetProvider()) { entry in
            BudgetWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget")
        .description("Monitor how you are sticking to your budgets.")
        .supportedFamilies([.systemSmall])
    }
}

struct BudgetWidgetProvider: IntentTimelineProvider {
    typealias Intent = BudgetWidgetConfigurationIntent

    public typealias Entry = BudgetWidgetEntry

    func placeholder(in _: Context) -> BudgetWidgetEntry {
        let loaded = loadData(budgetId: "")

        return BudgetWidgetEntry(date: Date(), totalSpent: loaded.total, percentageOfDays: loaded.percentage, budget: loaded.budget, configuration: BudgetWidgetConfigurationIntent())
    }

    func getSnapshot(for configuration: BudgetWidgetConfigurationIntent, in _: Context, completion: @escaping (BudgetWidgetEntry) -> Void) {
        let loaded = loadData(budgetId: configuration.budget?.identifier ?? "")

        let entry = BudgetWidgetEntry(date: Date(), totalSpent: loaded.total, percentageOfDays: loaded.percentage, budget: loaded.budget, configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: BudgetWidgetConfigurationIntent, in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let loaded = loadData(budgetId: configuration.budget?.identifier ?? "")

        let entry = BudgetWidgetEntry(date: Date(), totalSpent: loaded.total, percentageOfDays: loaded.percentage, budget: loaded.budget, configuration: configuration)

        let timeline = Timeline(entries: [entry], policy: .atEnd)

        completion(timeline)
    }

    func loadData(budgetId: String) -> (total: Double, percentage: Double, budget: HoldingBudget) {
//        let dataController = DataController()
        let dataController = DataController.shared

        if let objectIDURL = URL(string: budgetId) {
            let managedObjectID = dataController.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: objectIDURL)!

            let budget = dataController.container.viewContext.object(with: managedObjectID) as! Budget

            let fetchRequest = dataController.fetchRequestForBudgetTransactions(budget: budget)

            let transactions = dataController.results(for: fetchRequest)

            var holdingTotal = 0.0

            transactions.forEach { transaction in
                holdingTotal += transaction.wrappedAmount
            }

            let returnBudget = HoldingBudget(type: Int(budget.type), emoji: budget.wrappedEmoji, name: budget.wrappedName, colour: budget.wrappedColour, budgetAmount: budget.amount)

            let percentageOfDays: Double

            let calendar = Calendar.current

            if budget.type == 1 {
                let components = calendar.dateComponents([.minute], from: budget.startDate!, to: Date.now)
                percentageOfDays = Double(components.minute!) / 1440
            } else {
                let components1 = calendar.dateComponents([.day], from: budget.startDate!, to: budget.endDate)
                let numberOfDays = components1.day!

                let components2 = calendar.dateComponents([.day], from: budget.startDate!, to: Date.now)
                let numberOfDaysPast = components2.day!

                percentageOfDays = Double(numberOfDaysPast) / Double(numberOfDays)
            }

            return (holdingTotal, percentageOfDays, returnBudget)
        } else {
            let budget = HoldingBudget(type: 1, emoji: "failed", name: "", colour: "", budgetAmount: 0)
            return (0, 0, budget)
        }
    }
}

struct BudgetWidgetEntry: TimelineEntry {
    let date: Date
    let totalSpent: Double
    let percentageOfDays: Double
    let budget: HoldingBudget
    let configuration: BudgetWidgetConfigurationIntent
}

struct HoldingBudget {
    let type: Int
    let emoji: String
    let name: String
    let colour: String
    let budgetAmount: Double
}

struct BudgetWidgetEntryView: View {
    let entry: BudgetWidgetProvider.Entry

    var budgetType: String {
        switch entry.budget.type {
        case 1:
            return String(localized: "today")
        case 2:
            return String(localized: "this week")
        case 3:
            return String(localized: "this month")
        case 4:
            return String(localized: "this year")
        default:
            return "this week"
        }
    }

    var difference: Double {
        return abs(entry.budget.budgetAmount - entry.totalSpent)
    }

    var percentString1: String {
        return "\(Int(round((entry.totalSpent / entry.budget.budgetAmount) * 100)))%"
    }

    var systemSmallWidgetText: String {
        if entry.budget.budgetAmount >= entry.totalSpent {
            return String(localized: "left \(budgetType)")
        } else {
            return String(localized: "over \(budgetType)")
        }
    }

    func showTimeFrame(size: CGFloat) -> Bool {
        return size > systemSmallWidgetText.widthOfRoundedString(size: 10, weight: .semibold)
    }

    var body: some View {
        if entry.configuration.budget == nil {
            if #available(iOS 17.0, *) {
                Text("Select budget in widget options")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.SubtitleText)
                    .padding(15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .containerBackground(for: .widget) {
                        Color.PrimaryBackground
                    }
            } else {
                Text("Select budget in widget options")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.SubtitleText)
                    .padding(15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.PrimaryBackground)
            }

        } else if entry.budget.emoji == "failed" {
            if #available(iOS 17.0, *) {
                Text("Budget no longer exists - please select new budget from widget options.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.SubtitleText)
                    .padding(15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .containerBackground(for: .widget) {
                        Color.PrimaryBackground
                    }
            } else {
                Text("Budget no longer exists - please select new budget from widget options.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.SubtitleText)
                    .padding(15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.PrimaryBackground)
            }

        } else {
            if #available(iOS 17.0, *) {
                VStack(spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2.4) {
                            HStack(spacing: 5) {
                                Text(entry.budget.emoji)
                                    .font(.system(size: 9))
                                Text(entry.budget.name.uppercased())
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundColor(Color.PrimaryText)

                            Text("SPENT: \(percentString1)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Color.SubtitleText)
                        }

                        Spacer()

                        RingView(percent: entry.percentageOfDays, width: 2.4, topStroke: Color.DarkBackground, bottomStroke: Color.SecondaryBackground)
                            .frame(width: 13, height: 13)
                            .padding(3)
                    }
                    .frame(maxWidth: .infinity)

                    GeometryReader { proxy in
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                ZStack {
                                    DonutSemicircle(percent: 1, cornerRadius: 4, width: 15)
                                        .fill(Color.SecondaryBackground)
                                        .frame(width: proxy.size.width, height: proxy.size.width / 2)

                                    if entry.totalSpent / entry.budget.budgetAmount < 0.97 {
                                        DonutSemicircle(percent: 1 - (entry.totalSpent / entry.budget.budgetAmount), cornerRadius: 4, width: 15)
                                            .fill(Color(hex: entry.budget.colour))
                                            .frame(width: proxy.size.width, height: proxy.size.width / 2)
                                    }
                                }
                                .frame(width: proxy.size.width)

                                VStack(spacing: -4) {
                                    WidgetBudgetDollarView(amount: difference, red: entry.totalSpent >= entry.budget.budgetAmount, size: proxy.size.width - 50)

                                    if showTimeFrame(size: proxy.size.width - 50) {
                                        Text(systemSmallWidgetText)
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.SubtitleText)
                                    } else {
                                        if entry.budget.budgetAmount >= entry.totalSpent {
                                            Text("left")
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(Color.SubtitleText)
                                        } else {
                                            Text("over")
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(Color.SubtitleText)
                                        }
                                    }
                                }
                            }
                            .frame(width: proxy.size.width)

                            HStack {
                                if entry.totalSpent > 999.99 || entry.budget.budgetAmount > 999.99 {
                                    Text("\(Int(round(entry.totalSpent)))")
                                        .frame(width: 50, alignment: .leading)
                                    Spacer()
                                    Text("\(Int(round(entry.budget.budgetAmount)))")
                                        .frame(width: 50, alignment: .trailing)
                                } else {
                                    Text("\(entry.totalSpent, specifier: "%.2f")")
                                        .frame(width: 50, alignment: .leading)
                                    Spacer()
                                    Text("\(entry.budget.budgetAmount, specifier: "%.2f")")
                                        .frame(width: 50, alignment: .trailing)
                                }
                            }
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(for: .widget) {
                    Color.PrimaryBackground
                }
                .widgetURL(URL(string: "dimeapp://budget?budget=\(entry.budget.name)"))
            } else {
                VStack(spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2.4) {
                            HStack(spacing: 5) {
                                Text(entry.budget.emoji)
                                    .font(.system(size: 9))
                                Text(entry.budget.name.uppercased())
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundColor(Color.PrimaryText)

                            Text("SPENT: \(percentString1)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Color.SubtitleText)
                        }

                        Spacer()

                        RingView(percent: entry.percentageOfDays, width: 2.4, topStroke: Color.DarkBackground, bottomStroke: Color.SecondaryBackground)
                            .frame(width: 13, height: 13)
                            .padding(3)
                    }
                    .frame(maxWidth: .infinity)

                    GeometryReader { proxy in
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                ZStack {
                                    DonutSemicircle(percent: 1, cornerRadius: 4, width: 15)
                                        .fill(Color.SecondaryBackground)
                                        .frame(width: proxy.size.width, height: proxy.size.width / 2)

                                    if entry.totalSpent / entry.budget.budgetAmount < 0.97 {
                                        DonutSemicircle(percent: 1 - (entry.totalSpent / entry.budget.budgetAmount), cornerRadius: 4, width: 15)
                                            .fill(Color(hex: entry.budget.colour))
                                            .frame(width: proxy.size.width, height: proxy.size.width / 2)
                                    }
                                }
                                .frame(width: proxy.size.width)

                                VStack(spacing: -4) {
                                    WidgetBudgetDollarView(amount: difference, red: entry.totalSpent >= entry.budget.budgetAmount, size: proxy.size.width - 50)

                                    if showTimeFrame(size: proxy.size.width - 50) {
                                        Text(systemSmallWidgetText)
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.SubtitleText)
                                    } else {
                                        if entry.budget.budgetAmount >= entry.totalSpent {
                                            Text("left")
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(Color.SubtitleText)
                                        } else {
                                            Text("over")
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(Color.SubtitleText)
                                        }
                                    }
                                }
                            }
                            .frame(width: proxy.size.width)

                            HStack {
                                if entry.totalSpent > 999.99 || entry.budget.budgetAmount > 999.99 {
                                    Text("\(Int(round(entry.totalSpent)))")
                                        .frame(width: 50, alignment: .leading)
                                    Spacer()
                                    Text("\(Int(round(entry.budget.budgetAmount)))")
                                        .frame(width: 50, alignment: .trailing)
                                } else {
                                    Text("\(entry.totalSpent, specifier: "%.2f")")
                                        .frame(width: 50, alignment: .leading)
                                    Spacer()
                                    Text("\(entry.budget.budgetAmount, specifier: "%.2f")")
                                        .frame(width: 50, alignment: .trailing)
                                }
                            }
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .padding(15)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.PrimaryBackground)
                .widgetURL(URL(string: "dimeapp://budget?budget=\(entry.budget.name)"))
            }
        }
    }
}

// struct WidgetBudgetDollarView: View {
//    var string: String
//    var red: Bool
//
//    var currencySymbol: String {
//        return Locale.current.currencySymbol!
//    }
//
//    var dollarOffset: CGFloat {
//        let bigFont = UIFont.rounded(ofSize: 22, weight: .medium)
//        let smallFont = UIFont.rounded(ofSize: 14, weight: .regular)
//
//        return bigFont.capHeight - smallFont.capHeight - 1
//    }
//
//
//    var body: some View {
//        HStack(alignment: .lastTextBaseline, spacing: 1.3) {
//            Text(currencySymbol)
//                .font(.system(size: 14, weight: .regular, design: .rounded))
//                .foregroundColor(red ? Color("BudgetRed") : Color.SubtitleText)
//                .baselineOffset(dollarOffset)
//
//            Text(string)
//                .font(.system(size: 22, weight: .medium, design: .rounded))
//                .foregroundColor(red ? Color("BudgetRed") : Color.PrimaryText)
//                .lineLimit(1)
//
//
//
//        }
//    }
// }

struct WidgetBudgetDollarView: View {
    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    var amount: Double
    var red: Bool
    var size: CGFloat

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var downsize: (big: CGFloat, small: CGFloat) {
        let amountText: String

        if showCents && amount < 100 {
            amountText = String(format: "%.2f", amount)
        } else {
            amountText = String(format: "%.0f", amount)
        }

        if (amountText.widthOfRoundedString(size: 18, weight: .medium) + currencySymbol.widthOfRoundedString(size: 10, weight: .regular) + 1.3) > size {
            return (14, 8)
        } else if (amountText.widthOfRoundedString(size: 22, weight: .medium) + currencySymbol.widthOfRoundedString(size: 14, weight: .regular) + 1.3) > size {
            return (18, 10)
        } else {
            return (22, 14)
        }
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 1.3) {
            Text(currencySymbol)
                .font(.system(size: downsize.small, weight: .regular, design: .rounded))
                .foregroundColor(red ? Color("BudgetRed") : Color.SubtitleText)
                .baselineOffset(getDollarOffset(big: downsize.big, small: downsize.small))

            if showCents && amount < 100 {
                Text("\(amount, specifier: "%.2f")")
                    .font(.system(size: downsize.big, weight: .medium, design: .rounded))
                    .foregroundColor(red ? Color("BudgetRed") : Color.PrimaryText)
                    .lineLimit(1)
            } else {
                Text("\(amount, specifier: "%.0f")")
                    .font(.system(size: downsize.big, weight: .medium, design: .rounded))
                    .foregroundColor(red ? Color("BudgetRed") : Color.PrimaryText)
                    .lineLimit(1)
            }
        }
    }

    func getDollarOffset(big: CGFloat, small: CGFloat) -> CGFloat {
        let bigFont = UIFont.rounded(ofSize: big, weight: .medium)
        let smallFont = UIFont.rounded(ofSize: small, weight: .regular)

        return bigFont.capHeight - smallFont.capHeight - 1
    }
}
