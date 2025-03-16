//
//  MainBudgetWidget.swift
//  dime
//
//  Created by Rafael Soh on 12/1/23.
//

import SwiftUI
import WidgetKit

struct MainBudgetWidget: Widget {
    let kind: String = "MainBudgetWidget"

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOS 16.0, *) {
            return [
                .accessoryCircular,
                .accessoryRectangular,
                .systemSmall
            ]
        } else {
            return [.systemSmall]
        }
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MainBudgetWidgetProvider()) { entry in
            MainBudgetWidgetEntryView(entry: entry)
        }
        .supportedFamilies(supportedFamilies)
        .configurationDisplayName("Overall Budget")
        .description("Monitor how you are sticking to your overall budgets.")
    }
}

struct MainBudgetWidgetProvider: TimelineProvider {
    typealias Entry = MainBudgetWidgetEntry

    func placeholder(in _: Context) -> MainBudgetWidgetEntry {
        let loaded = loadData()

        return MainBudgetWidgetEntry(date: Date(), totalSpent: loaded.totalSpent, percentageOfDays: loaded.percentage, type: loaded.type, budgetAmount: loaded.budgetAmount, startDate: loaded.startDate, found: loaded.found)
    }

    func getSnapshot(in _: Context, completion: @escaping (MainBudgetWidgetEntry) -> Void) {
        let loaded = loadData()

        let entry = MainBudgetWidgetEntry(date: Date(), totalSpent: loaded.totalSpent, percentageOfDays: loaded.percentage, type: loaded.type, budgetAmount: loaded.budgetAmount, startDate: loaded.startDate, found: loaded.found)
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<MainBudgetWidgetEntry>) -> Void) {
        let loaded = loadData()

        let entry = MainBudgetWidgetEntry(date: Date(), totalSpent: loaded.totalSpent, percentageOfDays: loaded.percentage, type: loaded.type, budgetAmount: loaded.budgetAmount, startDate: loaded.startDate, found: loaded.found)

        let timeline = Timeline(entries: [entry], policy: .atEnd)

        completion(timeline)
    }

    func loadData() -> (found: Bool, totalSpent: Double, budgetAmount: Double, percentage: Double, type: Int, startDate: Date) {
//        let dataController = DataController()
        let dataController = DataController.shared

        return dataController.fetchRequestForMainBudgetWidget()
    }
}

struct MainBudgetWidgetEntry: TimelineEntry {
    let date: Date
    let totalSpent: Double
    let percentageOfDays: Double
    let type: Int
    let budgetAmount: Double
    let startDate: Date
    let found: Bool
}

struct MainBudgetWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: MainBudgetWidgetProvider.Entry

    var budgetType: String {
        switch entry.type {
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

    var headingText: String {
        let dateFormatter = DateFormatter()

        switch entry.type {
        case 1:
            dateFormatter.dateFormat = "d MMM yyyy"
            return dateFormatter.string(from: entry.startDate)
        case 2:
            dateFormatter.dateFormat = "d MMM"
            let endComponents = DateComponents(day: 7, second: -1)
            let endWeekDate = Calendar.current.date(byAdding: endComponents, to: entry.startDate)!
            return formatDateRange(date1: entry.startDate, date2: endWeekDate)
//            return dateFormatter.string(from: entry.startDate) + " - " + dateFormatter.string(from: endWeekDate)
        case 3:
            dateFormatter.dateFormat = "d MMM"
            let endComponents = DateComponents(month: 1, second: -1)
            let endWeekDate = Calendar.current.date(byAdding: endComponents, to: entry.startDate)!
            return formatDateRange(date1: entry.startDate, date2: endWeekDate)
//            return dateFormatter.string(from: entry.startDate) + " - " + dateFormatter.string(from: endWeekDate)
        case 4:
            dateFormatter.dateFormat = "d MMM yy"
            return dateFormatter.string(from: entry.startDate)
        default:
            return ""
        }
    }

    var difference: Double {
        return abs(entry.budgetAmount - entry.totalSpent)
    }

    var percentString: String {
        return String(localized: "\(Int(round((entry.totalSpent / entry.budgetAmount) * 100)))% spent")
    }

    var percentString1: String {
        return "\(Int(round((entry.totalSpent / entry.budgetAmount) * 100)))%"
    }

    var percent: Double {
        return entry.totalSpent / entry.budgetAmount
    }

    var systemSmallWidgetText: String {
        if entry.budgetAmount >= entry.totalSpent {
            return String(localized: "left \(budgetType)")
        } else {
            return String(localized: "over \(budgetType)")
        }
    }

    func showPercent(size: CGFloat) -> Bool {
        return size > headingText.widthOfRoundedString(size: 15, weight: .semibold) + 15 + percentString.widthOfRoundedString(size: 15, weight: .semibold)
    }

    func showTimeFrame(size: CGFloat) -> Bool {
        return size > systemSmallWidgetText.widthOfRoundedString(size: 10, weight: .semibold)
    }

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            if #available(iOS 17.0, *) {
                if !entry.found {
                    ZStack {
                        AccessoryWidgetBackground()

                        VStack {
                            Text("ADD\nBUDGET")
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .containerBackground(for: .widget) { AccessoryWidgetBackground() }
                } else {
                    Gauge(value: percent < 1 ? percent : 1) {
                        Image(systemName: "dollarsign.circle.fill")
                    } currentValueLabel: {
                        Text("\(Int(round(percent * 100)))%")
                    }
                    .gaugeStyle(AccessoryCircularGaugeStyle())
                    .containerBackground(for: .widget) { Color.clear }
                }
            } else {
                if !entry.found {
                    ZStack {
                        if #available(iOS 16.0, *) {
                            AccessoryWidgetBackground()
                        }

                        VStack {
                            Text("ADD BUDGET")
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    if #available(iOS 16.0, *) {
                        Gauge(value: percent < 1 ? percent : 1) {
                            Image(systemName: "dollarsign.circle.fill")
                        } currentValueLabel: {
                            Text("\(Int(round(percent * 100)))%")
                        }
                        .gaugeStyle(AccessoryCircularGaugeStyle())

                    } else {
                        EmptyView()
                    }
                }
            }

        case .accessoryRectangular:
            if #available(iOS 17.0, *) {
                if !entry.found {
                    Text("ADD OVERALL BUDGET")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .containerBackground(for: .widget) { Color.clear }
                } else {
                    GeometryReader { proxy in
                        VStack(alignment: .leading) {
                            HStack(spacing: 3) {
                                Text(headingText)

                                if showPercent(size: proxy.size.width) {
                                    Text("•")
                                    Text(percentString)
                                }
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))

                            Text("\(currencySymbol)\(difference, specifier: (showCents && difference < 100) ? "%.2f" : "%.0f") \(entry.totalSpent > entry.budgetAmount ? String(localized: "over") : String(localized: "left")) \(budgetType)")
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
                                Text("\(entry.budgetAmount, specifier: (showCents && entry.budgetAmount < 100) ? "%.2f" : "%.0f")")
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                            }
                            .frame(height: 5)
                            .gaugeStyle(.accessoryLinear)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .containerBackground(for: .widget) { Color.clear }
                }
            } else {
                if !entry.found {
                    Text("ADD OVERALL BUDGET")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                } else {
                    GeometryReader { proxy in
                        VStack(alignment: .leading) {
                            HStack(spacing: 3) {
                                Text(headingText)

                                if showPercent(size: proxy.size.width) {
                                    Text("•")
                                    Text(percentString)
                                }
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))

                            Text("\(currencySymbol)\(difference, specifier: (showCents && difference < 100) ? "%.2f" : "%.0f") \(entry.totalSpent > entry.budgetAmount ? String(localized: "over") : String(localized: "left")) \(budgetType)")
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
                                    Text("\(entry.budgetAmount, specifier: (showCents && entry.budgetAmount < 100) ? "%.2f" : "%.0f")")
                                        .font(.system(size: 10, weight: .regular, design: .rounded))
                                }
                                .frame(height: 5)
                                .gaugeStyle(.accessoryLinear)
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

        case .systemSmall:
            if #available(iOS 17.0, *) {
                if !entry.found {
                    Text("Create your overall budget in the app")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.SubtitleText)
                        .padding(15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .containerBackground(for: .widget) { Color.PrimaryBackground }
                } else {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2.4) {
                                Text(headingText.uppercased())
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
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

                                        if entry.totalSpent / entry.budgetAmount < 0.97 {
                                            DonutSemicircle(percent: 1 - (entry.totalSpent / entry.budgetAmount), cornerRadius: 4, width: 15)
                                                .fill(Color.DarkBackground)
                                                .frame(width: proxy.size.width, height: proxy.size.width / 2)
                                        }
                                    }
                                    .frame(width: proxy.size.width)

                                    VStack(spacing: -4) {
                                        WidgetBudgetDollarView(amount: difference, red: entry.totalSpent >= entry.budgetAmount)
                                            .frame(width: proxy.size.width - 50)

                                        if showTimeFrame(size: proxy.size.width - 50) {
                                            Text(systemSmallWidgetText)
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(Color.SubtitleText)
                                        } else {
                                            if entry.budgetAmount >= entry.totalSpent {
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
                                    if entry.totalSpent > 999.99 || entry.budgetAmount > 999.99 {
                                        Text("\(Int(round(entry.totalSpent)))")
                                            .frame(width: 50, alignment: .leading)
                                        Spacer()
                                        Text("\(Int(round(entry.budgetAmount)))")
                                            .frame(width: 50, alignment: .trailing)
                                    } else {
                                        Text("\(entry.totalSpent, specifier: "%.2f")")
                                            .frame(width: 50, alignment: .leading)
                                        Spacer()
                                        Text("\(entry.budgetAmount, specifier: "%.2f")")
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
                    .containerBackground(for: .widget) { Color.PrimaryBackground }
                }
            } else {
                if !entry.found {
                    Text("Create your overall budget in the app")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.SubtitleText)
                        .padding(15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.PrimaryBackground)
                } else {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2.4) {
                                Text(headingText.uppercased())
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
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

                                        if entry.totalSpent / entry.budgetAmount < 0.97 {
                                            DonutSemicircle(percent: 1 - (entry.totalSpent / entry.budgetAmount), cornerRadius: 4, width: 15)
                                                .fill(Color.DarkBackground)
                                                .frame(width: proxy.size.width, height: proxy.size.width / 2)
                                        }
                                    }
                                    .frame(width: proxy.size.width)

                                    VStack(spacing: -4) {
                                        WidgetBudgetDollarView(amount: difference, red: entry.totalSpent >= entry.budgetAmount)
                                            .frame(width: proxy.size.width - 50)

                                        if showTimeFrame(size: proxy.size.width - 50) {
                                            Text(systemSmallWidgetText)
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(Color.SubtitleText)
                                        } else {
                                            if entry.budgetAmount >= entry.totalSpent {
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
                                    if entry.totalSpent > 999.99 || entry.budgetAmount > 999.99 {
                                        Text("\(Int(round(entry.totalSpent)))")
                                            .frame(width: 50, alignment: .leading)
                                        Spacer()
                                        Text("\(Int(round(entry.budgetAmount)))")
                                            .frame(width: 50, alignment: .trailing)
                                    } else {
                                        Text("\(entry.totalSpent, specifier: "%.2f")")
                                            .frame(width: 50, alignment: .leading)
                                        Spacer()
                                        Text("\(entry.budgetAmount, specifier: "%.2f")")
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
                }
            }

        default:
            EmptyView()
        }
    }
}

func formatDateRange(date1: Date, date2: Date) -> String {
    let dateFormatter = DateFormatter()

    let calendar = Calendar.current
    let components1 = calendar.dateComponents([.day, .month], from: date1)
    let components2 = calendar.dateComponents([.day, .month], from: date2)

    if components1.month == components2.month {
        dateFormatter.dateFormat = "MMM"
        let dateString = dateFormatter.string(from: date1)
        return "\(components1.day!) - \(components2.day!) \(dateString)"
    } else {
        dateFormatter.dateFormat = "d MMM"
        let startDateString = dateFormatter.string(from: date1)
        let endDateString = dateFormatter.string(from: date2)
        return "\(startDateString) - \(endDateString)"
    }
}
