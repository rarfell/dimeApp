//
//  LockBudgetWidget.swift
//  ExpenditureWidgetExtension
//
//  Created by Rafael Soh on 9/9/22.
//

import SwiftUI
import WidgetKit

struct LockBudgetWidget: Widget {
    let kind: String = "LockBudgetWidget"

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 16, *) {
            return [
                .accessoryCircular,
                .accessoryRectangular,
                .accessoryInline
            ]
        } else {
            return [WidgetFamily]()
        }
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: BudgetWidgetConfigurationIntent.self, provider: LockBudgetWidgetProvider()) { entry in
            LockBudgetWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget")
        .description("Monitor how you are sticking to your budgets.")
        .supportedFamilies(supportedFamilies)
    }
}

struct LockBudgetWidgetProvider: IntentTimelineProvider {
    typealias Intent = BudgetWidgetConfigurationIntent

    public typealias Entry = LockBudgetWidgetEntry

    func placeholder(in _: Context) -> LockBudgetWidgetEntry {
        let loaded = loadData(budgetId: "")

        return LockBudgetWidgetEntry(date: Date(), totalSpent: loaded.total, timeLeft: loaded.timeLeft, budget: loaded.budget, configuration: BudgetWidgetConfigurationIntent())
    }

    func getSnapshot(for configuration: BudgetWidgetConfigurationIntent, in _: Context, completion: @escaping (LockBudgetWidgetEntry) -> Void) {
        let loaded = loadData(budgetId: configuration.budget?.identifier ?? "")

        let entry = LockBudgetWidgetEntry(date: Date(), totalSpent: loaded.total, timeLeft: loaded.timeLeft, budget: loaded.budget, configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: BudgetWidgetConfigurationIntent, in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let loaded = loadData(budgetId: configuration.budget?.identifier ?? "")

        let entry = LockBudgetWidgetEntry(date: Date(), totalSpent: loaded.total, timeLeft: loaded.timeLeft, budget: loaded.budget, configuration: configuration)

        let timeline = Timeline(entries: [entry], policy: .atEnd)

        completion(timeline)
    }

    func loadData(budgetId: String) -> (total: Double, timeLeft: String, budget: HoldingBudget) {
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

            let timeLeft: String

            let calendar = Calendar.current

            if budget.type == 1 {
                let components = calendar.dateComponents([.hour], from: budget.startDate!, to: Date.now)

                timeLeft = String(localized: "\(24 - components.hour!) hours left")
            } else if budget.type == 2 {
                let components = calendar.dateComponents([.day], from: budget.startDate!, to: Date.now)

                timeLeft = String(localized: "\(7 - components.day!) days left")
            } else {
                let components1 = calendar.dateComponents([.day], from: budget.startDate!, to: budget.endDate)
                let numberOfDays = components1.day!

                let components2 = calendar.dateComponents([.day], from: budget.startDate!, to: Date.now)
                let numberOfDaysPast = components2.day!

                let daysLeftNumber = Int(numberOfDays - numberOfDaysPast)
                timeLeft = String(localized: "\(daysLeftNumber) days left")
            }

            return (holdingTotal, timeLeft, returnBudget)
        } else {
            let budget = HoldingBudget(type: 1, emoji: "failed", name: "", colour: "", budgetAmount: 0)
            return (0, "", budget)
        }
    }
}

struct LockBudgetWidgetEntry: TimelineEntry {
    let date: Date
    let totalSpent: Double
    let timeLeft: String
    let budget: HoldingBudget
    let configuration: BudgetWidgetConfigurationIntent
}

struct LockBudgetWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: LockBudgetWidgetProvider.Entry

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

    var subtitle: String {
        if entry.budget.budgetAmount > entry.totalSpent {
            return String(localized: "left")
        } else {
            return String(localized: "over")
        }
    }

    var difference: Double {
        return abs(entry.budget.budgetAmount - entry.totalSpent)
    }

    var percent: Double {
        return entry.totalSpent / entry.budget.budgetAmount
    }

    var percentString: String {
        return String(localized: "\(Int(round((entry.totalSpent / entry.budget.budgetAmount) * 100)))% spent")
    }

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            if entry.configuration.budget == nil {
                Text("Select budget in widget options")
            } else {
                Text("\(entry.budget.emoji) \(currencySymbol)\(difference, specifier: (showCents && difference < 100) ? "%.2f" : "%.0f") \(subtitle)")
                    .widgetURL(URL(string: "dimeapp://budget?budget=\(entry.budget.name)"))
            }

        case .accessoryCircular:
            if #available(iOS 17.0, *) {
                if entry.configuration.budget == nil {
                    ZStack {
                        AccessoryWidgetBackground()

                        Text("SELECT BUDGET")
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .containerBackground(for: .widget) { AccessoryWidgetBackground() }
                } else {
                    Gauge(value: percent < 1 ? percent : 1) {
                        Text(entry.budget.emoji)
                    } currentValueLabel: {
                        Text("\(Int(round(percent * 100)))%")
                    }
                    .gaugeStyle(AccessoryCircularGaugeStyle())
                    .widgetURL(URL(string: "dimeapp://budget?budget=\(entry.budget.name)"))
                    .containerBackground(for: .widget) { Color.clear }
                }
            } else {
                if entry.configuration.budget == nil {
                    ZStack {
                        if #available(iOS 16.0, *) {
                            AccessoryWidgetBackground()
                        }

                        VStack {
                            Text("SELECT BUDGET")
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    if #available(iOS 16.0, *) {
                        Gauge(value: percent < 1 ? percent : 1) {
                            Text(entry.budget.emoji)
                        } currentValueLabel: {
                            Text("\(Int(round(percent * 100)))%")
                        }
                        .gaugeStyle(AccessoryCircularGaugeStyle())
                        .widgetURL(URL(string: "dimeapp://budget?budget=\(entry.budget.name)"))
                    } else {
                        EmptyView()
                    }
                }
            }

        case .accessoryRectangular:
            if #available(iOS 17.0, *) {
                if entry.configuration.budget == nil {
                    Text("SELECT BUDGET IN WIDGET OPTIONS")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .containerBackground(for: .widget) { Color.clear }
                } else {
                    GeometryReader { proxy in
                        VStack(alignment: .leading) {
                            HStack(spacing: 3) {
                                Text(entry.budget.name)

                                if showPercent(size: proxy.size.width) {
                                    Text("•")
                                    Text(percentString)
                                }
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))

                            Text("\(currencySymbol)\(difference, specifier: (showCents && difference < 100) ? "%.2f" : "%.0f") \(subtitle) \(budgetType)")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(Color.SubtitleText)

                            Gauge(value: percent, in: 0 ... 1) {
                                Text("Percent Spent")
                            } currentValueLabel: {
                                EmptyView()
                            } minimumValueLabel: {
                                Text("\(entry.totalSpent, specifier: (showCents && entry.totalSpent < 100) ? "%.2f" : "%.0f")")
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                            } maximumValueLabel: {
                                Text("\(entry.budget.budgetAmount, specifier: (showCents && entry.budget.budgetAmount < 100) ? "%.2f" : "%.0f")")
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                            }
                            .frame(height: 5)
                            .gaugeStyle(.accessoryLinear)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .widgetURL(URL(string: "dimeapp://budget?budget=\(entry.budget.name)"))
                    .containerBackground(for: .widget) { Color.clear }
                }
            } else {
                if entry.configuration.budget == nil {
                    Text("SELECT BUDGET IN WIDGET OPTIONS")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                } else {
                    GeometryReader { proxy in
                        VStack(alignment: .leading) {
                            HStack(spacing: 3) {
                                Text(entry.budget.name)

                                if showPercent(size: proxy.size.width) {
                                    Text("•")
                                    Text(percentString)
                                }
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))

                            Text("\(currencySymbol)\(difference, specifier: (showCents && difference < 100) ? "%.2f" : "%.0f") \(subtitle) \(budgetType)")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(Color.SubtitleText)

                            if #available(iOS 16.0, *) {
                                Gauge(value: percent, in: 0 ... 1) {
                                    Text("Percent Spent")
                                } currentValueLabel: {
                                    EmptyView()
                                } minimumValueLabel: {
                                    Text("\(entry.totalSpent, specifier: (showCents && entry.totalSpent < 100) ? "%.2f" : "%.0f")")
                                        .font(.system(size: 10, weight: .regular, design: .rounded))
                                } maximumValueLabel: {
                                    Text("\(entry.budget.budgetAmount, specifier: (showCents && entry.budget.budgetAmount < 100) ? "%.2f" : "%.0f")")
                                        .font(.system(size: 10, weight: .regular, design: .rounded))
                                }
                                .frame(height: 5)
                                .gaugeStyle(.accessoryLinear)
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .widgetURL(URL(string: "dimeapp://budget?budget=\(entry.budget.name)"))
                }
            }

        default:
            EmptyView()
        }
    }

    func showPercent(size: CGFloat) -> Bool {
        return size > entry.budget.name.widthOfRoundedString(size: 15, weight: .semibold) + 15 + percentString.widthOfRoundedString(size: 15, weight: .semibold)
    }
}
