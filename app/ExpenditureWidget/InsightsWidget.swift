//
//  InsightsWidget.swift
//  dime
//
//  Created by Rafael Soh on 14/8/22.
//

import Foundation
import SwiftUI
import WidgetKit

struct InsightsWidget: Widget {
    let kind: String = "InsightsWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: InsightsWidgetConfigurationIntent.self, provider: InsightsProvider()) { entry in
            InsightsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Insights")
        .description("Analyse your expenditure breakdowns over various time periods.")
        .supportedFamilies([.systemMedium])
    }
}

struct InsightsProvider: IntentTimelineProvider {
    typealias Intent = InsightsWidgetConfigurationIntent

    public typealias Entry = InsightsWidgetEntry

    func placeholder(in _: Context) -> InsightsWidgetEntry {
        let results = loadData(type: .week, income: true)

        return InsightsWidgetEntry(date: Date(), amount: results.amount, duration: .week, maximum: results.maximum, dates: results.dates, dictionary: results.dateDictionary, numberOfDays: results.numberOfDays, average: results.average, categories: results.categories, income: true)
    }

    func getSnapshot(for configuration: InsightsWidgetConfigurationIntent, in _: Context, completion: @escaping (InsightsWidgetEntry) -> Void) {
        let loaded = loadData(type: configuration.duration, income: configuration.income == .income)

        let entry = InsightsWidgetEntry(date: Date(), amount: loaded.amount, duration: configuration.duration, maximum: loaded.maximum, dates: loaded.dates, dictionary: loaded.dateDictionary, numberOfDays: loaded.numberOfDays, average: loaded.average, categories: loaded.categories, income: configuration.income == .income)
        completion(entry)
    }

    func getTimeline(for configuration: InsightsWidgetConfigurationIntent, in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let loaded = loadData(type: configuration.duration, income: configuration.income == .income)

        let entry = InsightsWidgetEntry(date: Date(), amount: loaded.amount, duration: configuration.duration, maximum: loaded.maximum, dates: loaded.dates, dictionary: loaded.dateDictionary, numberOfDays: loaded.numberOfDays, average: loaded.average, categories: loaded.categories, income: configuration.income == .income)

        let timeline = Timeline(entries: [entry], policy: .atEnd)

        completion(timeline)
    }

    func loadData(type: InsightsTimePeriod, income: Bool) -> (amount: Double, maximum: Double, average: Double, numberOfDays: Int, dates: [Date], dateDictionary: [Date: Double], categories: [HoldingCategory]) {
//        let dataController = DataController()
        let dataController = DataController.shared
        let itemRequest = dataController.fetchRequestForWidgetInsights(type: type, income: income)
        let categoryRequest = dataController.fetchRequestForCategories(income: income)

        let categories = dataController.results(for: categoryRequest)
        let transactions = dataController.results(for: itemRequest.fetchRequest)
        var iterativeDate = itemRequest.date

        switch type {
        case .unknown:
            return (0, 0, 0, 0, [Date](), [Date: Double](), [HoldingCategory]())
        case .week:
            var dates = [Date]()
            var nextDate = iterativeDate

            // calendar initialization
            var calendar = Calendar(identifier: .gregorian)

            calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
            calendar.minimumDaysInFirstWeek = 4

            var dictionary = [Date: Double]()
            var totalForWeek = 0.0
            var maximum = 0.0
            var numberOfDays = 0

            for _ in 1 ... 7 {
                nextDate = calendar.date(byAdding: .day, value: 1, to: iterativeDate)!

                let holding = transactions.filter {
                    $0.wrappedDate >= iterativeDate && $0.wrappedDate < nextDate
                }

                var total = 0.0

                holding.forEach { transaction in
                    total += transaction.wrappedAmount
                }

                totalForWeek += total

                dictionary[iterativeDate] = total

                if total > maximum {
                    maximum = total
                }

                if total != 0 {
                    numberOfDays += 1
                }

                dates.append(iterativeDate)
                iterativeDate = nextDate
            }

            let numberOfDaysPast = Calendar.current.dateComponents([.day], from: itemRequest.date, to: Date.now)

            var holdingCat = [HoldingCategory]()

            for category in categories {
                let holding = transactions.filter {
                    $0.category == category
                }

                var total = 0.0

                holding.forEach { transaction in
                    total += transaction.wrappedAmount
                }

                if total == 0 {
                    continue
                }

                let newCategory = HoldingCategory(colour: category.wrappedColour, name: category.wrappedName, percent: total / totalForWeek)

                holdingCat.append(newCategory)
            }

            holdingCat.sort(by: { lhs, rhs in
                lhs.percent > rhs.percent
            })

            return (totalForWeek, maximum, totalForWeek / Double((numberOfDaysPast.day! + 1)), numberOfDays, dates, dictionary, holdingCat)
        case .month:
            var dates = [Date]()
            var nextDate = iterativeDate

            let calendar = Calendar(identifier: .gregorian)
            let range = calendar.range(of: .day, in: .month, for: iterativeDate)!

            var dictionary = [Date: Double]()
            var totalForMonth = 0.0
            var maximum = 0.0
            var numberOfDays = 0

            for _ in 1 ... range.count {
                nextDate = calendar.date(byAdding: .day, value: 1, to: iterativeDate)!

                let holding = transactions.filter {
                    $0.wrappedDate >= iterativeDate && $0.wrappedDate < nextDate
                }

                var total = 0.0

                holding.forEach { transaction in
                    total += transaction.wrappedAmount
                }

                totalForMonth += total

                dictionary[iterativeDate] = total

                if total > maximum {
                    maximum = total
                }

                if total != 0 {
                    numberOfDays += 1
                }

                dates.append(iterativeDate)
                iterativeDate = nextDate
            }

            let numDays = Calendar.current.dateComponents([.day], from: itemRequest.date, to: Date.now)

            var holdingCat = [HoldingCategory]()

            for category in categories {
                let holding = transactions.filter {
                    $0.category == category
                }

                var total = 0.0

                holding.forEach { transaction in
                    total += transaction.wrappedAmount
                }

                if total == 0 {
                    continue
                }

                let newCategory = HoldingCategory(colour: category.wrappedColour, name: category.wrappedName, percent: total / totalForMonth)

                holdingCat.append(newCategory)
            }

            holdingCat.sort(by: { lhs, rhs in
                lhs.percent > rhs.percent
            })

            return (totalForMonth, maximum, totalForMonth / Double((numDays.day! + 1)), numberOfDays, dates, dictionary, holdingCat)
        case .year:
            // trackin dates
            var dates = [Date]()
            var nextDate = iterativeDate

            let calendar = Calendar(identifier: .gregorian)

            var dictionary = [Date: Double]()
            var totalForYear = 0.0
            var maximum = 0.0
            var numberOfDays = 0

            for _ in 1 ... 12 {
                nextDate = calendar.date(byAdding: .month, value: 1, to: iterativeDate)!

                let holding = transactions.filter {
                    $0.wrappedDate >= iterativeDate && $0.wrappedDate < nextDate
                }

                var total = 0.0

                holding.forEach { transaction in
                    total += transaction.wrappedAmount
                }

                totalForYear += total

                dictionary[iterativeDate] = total

                if total > maximum {
                    maximum = total
                }

                if total != 0 {
                    numberOfDays += 1
                }

                dates.append(iterativeDate)
                iterativeDate = nextDate
            }

            let numDays = Calendar.current.dateComponents([.month], from: itemRequest.date, to: Date.now)

            var holdingCat = [HoldingCategory]()

            for category in categories {
                let holding = transactions.filter {
                    $0.category == category
                }

                var total = 0.0

                holding.forEach { transaction in
                    total += transaction.wrappedAmount
                }

                if total == 0 {
                    continue
                }

                let newCategory = HoldingCategory(colour: category.wrappedColour, name: category.wrappedName, percent: total / totalForYear)

                holdingCat.append(newCategory)
            }

            holdingCat.sort(by: { lhs, rhs in
                lhs.percent > rhs.percent
            })

            return (totalForYear, maximum, totalForYear / Double((numDays.month! + 1)), numberOfDays, dates, dictionary, holdingCat)
        }
    }
}

struct InsightsWidgetEntry: TimelineEntry {
    let date: Date
    let amount: Double
    let duration: InsightsTimePeriod
    let maximum: Double
    let dates: [Date]
    let dictionary: [Date: Double]
    let numberOfDays: Int
    let average: Double
    let categories: [HoldingCategory]
    let income: Bool
}

struct InsightsWidgetEntryView: View {
    let entry: InsightsProvider.Entry

    let numberArray = [1, 8, 15, 22, 29]
    let monthNumberArray = [1, 4, 7, 10]
    let monthNames: [Int: String] = [1: "Jan", 4: "Apr", 7: "Jul", 10: "Oct"]

    @AppStorage("firstDayOfMonth", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var firstDayOfMonth: Int = 1
    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    var dollarText: String {
        if entry.amount < 10000 && showCents {
            return "\(String(format: "%.2f", entry.amount))"
        } else {
            return "\(Int(round(entry.amount)))"
        }
    }

    var subtitleText: String {
        switch entry.duration {
        case .unknown:
            return "NIL"
        case .week:
            return String(localized: "THIS WEEK").uppercased()
        case .month:
            return String(localized: "THIS MONTH").uppercased()
        case .year:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return String(localized: "in \(formatter.string(from: Date.now))").uppercased()
        }
    }

    var subtitleText1: String {
        switch entry.duration {
        case .unknown:
            return "NIL"
        case .week:
            return String(localized: "THIS WEEK").uppercased()
        case .month:
            return String(localized: "THIS MONTH").uppercased()
        case .year:
            return String(localized: "THIS YEAR").uppercased()
        }
    }

    var verbText: String {
        if entry.income {
            return String(localized: "EARNED ").uppercased()
        } else {
            return String(localized: "SPENT ").uppercased()
        }
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    VStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: -1) {
                            Text(verbText + subtitleText)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.SubtitleText)

                            InsightsWidgetDollarView(currencySymbol: currencySymbol, dollarText: dollarText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        GeometryReader { proxy in
                            ZStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 4) {
                                    // axes
                                    VStack(alignment: .leading) {
                                        Text(getMaxText())
                                            .lineLimit(1)
                                            .font(.system(size: 8, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.SubtitleText)

                                        Spacer()

                                        Text("0")
                                            .font(.system(size: 8, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.SubtitleText)
                                    }
                                    .frame(height: proxy.size.height * 0.85)

                                    if entry.duration == .week {
                                        HStack(spacing: 3) {
                                            ForEach(entry.dates, id: \.self) { day in
                                                VStack(spacing: 3) {
                                                    ZStack(alignment: .bottom) {
                                                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                                            .fill(Color.SecondaryBackground)
                                                            .frame(height: proxy.size.height * 0.85)

                                                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                                            .frame(height: getBarHeight(point: entry.dictionary[day]!, size: proxy.size))
                                                    }

                                                    Text(getWeekday(day: day).prefix(1))
                                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                                        .foregroundColor(Color.SubtitleText)
                                                }
                                                .opacity(day > Date.now ? 0.3 : 1)
                                                .frame(maxWidth: .infinity)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    } else if entry.duration == .month {
                                        HStack(spacing: 1.5) {
                                            ForEach(entry.dates, id: \.self) { day in
                                                ZStack(alignment: .bottom) {
                                                    Capsule()
                                                        .fill(Color.SecondaryBackground)
                                                        .frame(height: proxy.size.height * 0.85)

                                                    Capsule()
                                                        .frame(height: getBarHeight(point: entry.dictionary[day]!, size: proxy.size))
                                                        .overlay(alignment: .bottom) {
                                                            if numberArray.contains((entry.dates.firstIndex(of: day) ?? -1) + 1) && firstDayOfMonth == 1 {
                                                                Text("\((entry.dates.firstIndex(of: day) ?? -1) + 1)")
                                                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                                                    .foregroundColor(Color.SubtitleText)
                                                                    .frame(width: 20, alignment: .center)
                                                                    .offset(y: 15)
                                                            }
                                                        }
                                                }
                                                .padding(.bottom, firstDayOfMonth == 1 ? 13 : 0)
                                                .opacity(day > Date.now ? 0.3 : 1)
                                                .frame(maxWidth: .infinity)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    } else {
                                        HStack(spacing: 2.5) {
                                            ForEach(entry.dates, id: \.self) { day in
                                                ZStack(alignment: .bottom) {
                                                    RoundedRectangle(cornerRadius: 2.7, style: .continuous)
                                                        .fill(Color.SecondaryBackground)
                                                        .frame(height: proxy.size.height * 0.85)

                                                    RoundedRectangle(cornerRadius: 2.7, style: .continuous)
                                                        .frame(height: getBarHeight(point: entry.dictionary[day]!, size: proxy.size))
                                                        .overlay(alignment: .bottom) {
                                                            if monthNumberArray.contains((entry.dates.firstIndex(of: day) ?? -1) + 1) {
                                                                Text(LocalizedStringKey(monthNames[(entry.dates.firstIndex(of: day)! + 1)] ?? ""))
                                                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                                                    .foregroundColor(Color.SubtitleText)
                                                                    .frame(width: 20, alignment: .center)
                                                                    .offset(y: 15)
                                                            }
                                                        }
                                                }
                                                .padding(.bottom, 13)
                                                .opacity(day > Date.now ? 0.3 : 1)
                                                .frame(maxWidth: .infinity)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(width: proxy.size.width)
                                .frame(maxHeight: .infinity)

                                HStack(spacing: 4) {
                                    Text(getAverageText())
                                        .lineLimit(1)
                                        .font(.system(size: 8, weight: .regular, design: .rounded))
                                        .foregroundColor(Color.PrimaryText)
                                        .opacity((entry.average / Double(getMax())) < 0.2 || (entry.average / Double(getMax())) > 0.8 ? 0 : 1)

                                    Line()
                                        .stroke(Color.SubtitleText, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5]))
                                        .frame(height: 1)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(width: proxy.size.width)
                                .opacity(entry.numberOfDays <= 1 ? 0 : 1)
                                .offset(y: getOffset(size: proxy.size) - 5)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding([.trailing], 20)
                    .frame(width: 185)
                    .frame(maxHeight: .infinity)
                    .background(Color.PrimaryBackground)

                    InsightsWidgetCategoryBreakdownView(amount: entry.amount, income: entry.income, categories: entry.categories, duration: entry.duration, ios17: true)
//                    .frame(width: proxy.size.width * 0.43)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(URL(string: "dimeapp://insights"))
            .containerBackground(for: .widget) {
                Color.PrimaryBackground
            }
        } else {
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    VStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: -1) {
                            Text(verbText + subtitleText)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.SubtitleText)

                            InsightsWidgetDollarView(currencySymbol: currencySymbol, dollarText: dollarText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        GeometryReader { proxy in
                            ZStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 4) {
                                    // axes
                                    VStack(alignment: .leading) {
                                        Text(getMaxText())
                                            .lineLimit(1)
                                            .font(.system(size: 8, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.SubtitleText)

                                        Spacer()

                                        Text("0")
                                            .font(.system(size: 8, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.SubtitleText)
                                    }
                                    .frame(height: proxy.size.height * 0.85)

                                    if entry.duration == .week {
                                        HStack(spacing: 3) {
                                            ForEach(entry.dates, id: \.self) { day in
                                                VStack(spacing: 3) {
                                                    ZStack(alignment: .bottom) {
                                                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                                            .fill(Color.SecondaryBackground)
                                                            .frame(height: proxy.size.height * 0.85)

                                                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                                            .frame(height: getBarHeight(point: entry.dictionary[day]!, size: proxy.size))
                                                    }

                                                    Text(getWeekday(day: day).prefix(1))
                                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                                        .foregroundColor(Color.SubtitleText)
                                                }
                                                .opacity(day > Date.now ? 0.3 : 1)
                                                .frame(maxWidth: .infinity)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    } else if entry.duration == .month {
                                        HStack(spacing: 1.5) {
                                            ForEach(entry.dates, id: \.self) { day in
                                                ZStack(alignment: .bottom) {
                                                    Capsule()
                                                        .fill(Color.SecondaryBackground)
                                                        .frame(height: proxy.size.height * 0.85)

                                                    Capsule()
                                                        .frame(height: getBarHeight(point: entry.dictionary[day]!, size: proxy.size))
                                                        .overlay(alignment: .bottom) {
                                                            if numberArray.contains((entry.dates.firstIndex(of: day) ?? -1) + 1) && firstDayOfMonth == 1 {
                                                                Text("\((entry.dates.firstIndex(of: day) ?? -1) + 1)")
                                                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                                                    .foregroundColor(Color.SubtitleText)
                                                                    .frame(width: 20, alignment: .center)
                                                                    .offset(y: 15)
                                                            }
                                                        }
                                                }
                                                .padding(.bottom, firstDayOfMonth == 1 ? 13 : 0)
                                                .opacity(day > Date.now ? 0.3 : 1)
                                                .frame(maxWidth: .infinity)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    } else {
                                        HStack(spacing: 2.5) {
                                            ForEach(entry.dates, id: \.self) { day in
                                                ZStack(alignment: .bottom) {
                                                    RoundedRectangle(cornerRadius: 2.7, style: .continuous)
                                                        .fill(Color.SecondaryBackground)
                                                        .frame(height: proxy.size.height * 0.85)

                                                    RoundedRectangle(cornerRadius: 2.7, style: .continuous)
                                                        .frame(height: getBarHeight(point: entry.dictionary[day]!, size: proxy.size))
                                                        .overlay(alignment: .bottom) {
                                                            if monthNumberArray.contains((entry.dates.firstIndex(of: day) ?? -1) + 1) {
                                                                Text(LocalizedStringKey(monthNames[(entry.dates.firstIndex(of: day)! + 1)] ?? ""))
                                                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                                                    .foregroundColor(Color.SubtitleText)
                                                                    .frame(width: 20, alignment: .center)
                                                                    .offset(y: 15)
                                                            }
                                                        }
                                                }
                                                .padding(.bottom, 13)
                                                .opacity(day > Date.now ? 0.3 : 1)
                                                .frame(maxWidth: .infinity)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(width: proxy.size.width)
                                .frame(maxHeight: .infinity)

                                HStack(spacing: 4) {
                                    Text(getAverageText())
                                        .lineLimit(1)
                                        .font(.system(size: 8, weight: .regular, design: .rounded))
                                        .foregroundColor(Color.PrimaryText)
                                        .opacity((entry.average / Double(getMax())) < 0.2 || (entry.average / Double(getMax())) > 0.8 ? 0 : 1)

                                    Line()
                                        .stroke(Color.SubtitleText, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5]))
                                        .frame(height: 1)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(width: proxy.size.width)
                                .opacity(entry.numberOfDays <= 1 ? 0 : 1)
                                .offset(y: getOffset(size: proxy.size) - 5)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(15)
                    .frame(width: proxy.size.width * 0.57)
                    .frame(maxHeight: .infinity)
                    .background(Color.PrimaryBackground)

                    InsightsWidgetCategoryBreakdownView(amount: entry.amount, income: entry.income, categories: entry.categories, duration: entry.duration, ios17: false)
                    .padding(15)
                    .frame(width: proxy.size.width * 0.43)
                    .frame(maxHeight: .infinity)
                    .background(Color.SecondaryBackground)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .widgetURL(URL(string: "dimeapp://insights"))
        }
    }

    func getOffset(size: CGSize) -> Double {
        let maxi = getMax()

        if maxi == 0 {
            return 0
        } else {
            let height = (size.height * 0.85) - ((entry.average / Double(maxi)) * (size.height * 0.85))
            return height
        }
    }

    func getAverageText() -> String {
        let string = String(entry.average)

        let stringArray = string.compactMap { String($0) }

        if entry.average >= 1_000_000 {
            return stringArray[0] + "M"
        } else if entry.average >= 100_000 {
            return string.prefix(3) + "k"
        } else if entry.average >= 10000 {
            return string.prefix(2) + "k"
        } else if entry.average >= 1000 {
            return stringArray[0] + "." + stringArray[1] + "k"
        } else {
            return String(Int(round(entry.average)))
        }
    }

    func getMaxText() -> String {
        let maxi = getMax()

        if maxi == 0 {
            return "10"
        }

        let string = String(maxi)

        let stringArray = string.compactMap { String($0) }

        if maxi >= 1_000_000 {
            return stringArray[0] + "M"
        } else if maxi >= 100_000 {
            return string.prefix(3) + "k"
        } else if maxi >= 10000 {
            return string.prefix(2) + "k"
        } else if maxi >= 1000 {
            let string = String(maxi)

            let stringArray = string.compactMap { String($0) }

            return stringArray[0] + "." + stringArray[1] + "k"
        } else {
            return String(maxi)
        }
    }

    func getMax() -> Int {
        let maximum = entry.maximum * 1.1

        return Int(ceil(maximum / 10) * 10)
    }

    func getBarHeight(point: CGFloat, size: CGSize) -> CGFloat {
        let maxi = getMax()

        if maxi == 0 {
            return 0
        } else {
            let height = (point / CGFloat(maxi)) * (size.height * 0.85)
            return height
        }
    }

    func getWeekday(day: Date) -> String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "EEE"

        return dateFormatter.string(from: day)
    }
}

struct HoldingCategory: Hashable {
    let colour: String
    let name: String
    let percent: Double
}

struct HorizontalBarGraph: View {
    var categories: [HoldingCategory]
    let income: Bool

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: proxy.size.width * 0.015) {
                ForEach(categories, id: \.self) { category in
                    if category.percent < 0.02 {
                        EmptyView()
                    } else if category.percent < 0.1 {
                        RoundedRectangle(cornerRadius: 0.09 + (0.25 * category.percent * 100), style: .continuous)
                            .fill(income ? Color(hex: Color.colorArray[categories.firstIndex(of: category) ?? 0]) : Color(hex: category.colour))
                            .frame(width: (proxy.size.width * (1.0 - (0.015 * Double(categories.count - 1)))) * category.percent)

                    } else {
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .fill(income ? Color(hex: Color.colorArray[categories.firstIndex(of: category) ?? 0]) : Color(hex: category.colour))
                            .frame(width: (proxy.size.width * (1.0 - (0.015 * Double(categories.count - 1)))) * category.percent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct InsightsWidgetDollarView: View {
    let currencySymbol: String
    let dollarText: String

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 1.3) {
            Group {
                Text(currencySymbol)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(Color.SubtitleText) +

                Text(dollarText)
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundColor(Color.PrimaryText)
            }

        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

struct InsightsWidgetCategoryBreakdownView: View {
    let amount: Double
    let income: Bool
    let categories: [HoldingCategory]
    let duration: InsightsTimePeriod
    let ios17: Bool

    var subtitleText1: String {
        switch duration {
        case .unknown:
            return "NIL"
        case .week:
            return String(localized: "THIS WEEK").uppercased()
        case .month:
            return String(localized: "THIS MONTH").uppercased()
        case .year:
            return String(localized: "THIS YEAR").uppercased()
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            if amount != 0 {
                HorizontalBarGraph(categories: categories, income: income)
                    .frame(height: 16)

                VStack(spacing: 5) {
                    ForEach(Array(categories.prefix(3)), id: \.self) { category in
                        HStack(spacing: 7) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(income ? Color(hex: Color.colorArray[categories.firstIndex(of: category) ?? 0]) : Color(hex: category.colour))
                                .frame(width: 8, height: 8)
                            Text(category.name)
                                .lineLimit(1)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.PrimaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(Int(round(category.percent * 100)))%")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(Color.SubtitleText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                Text("NO TRANSACTIONS\n\(subtitleText1)")
                    .font(.system(size: 10,
                                  weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.SubtitleText)
                    .frame(maxHeight: .infinity)
            }

            Link(destination: URL(string: "dimeapp://newExpense")!) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .medium, design: .rounded))

                    Text("New Expense")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 5).fill(ios17 ? Color.SecondaryBackground : Color.PrimaryBackground))
            }
        }
    }
}
