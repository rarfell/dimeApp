//
//  InsightsView.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import Foundation
import Introspect
import Popovers
import SwiftUI

struct InsightsView: View {
    @FetchRequest(sortDescriptors: []) private var transactions: FetchedResults<Transaction>

    @State private var showTimeMenu = false
    @AppStorage("chartTimeFrame", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var chartType = 1

    private var didSave = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
    @State private var refreshID = UUID()

    var chartTypeString: String {
        if chartType == 1 {
            return "week"
        } else if chartType == 2 {
            return "month"
        } else if chartType == 3 {
            return "year"
        } else {
            return ""
        }
    }

//    @State private var holdingIncome = false
//    @Namespace var animation

    var body: some View {
        if transactions.isEmpty {
            VStack(spacing: 5) {
                Image("chart")
                    .resizable()
                    .frame(width: 75, height: 75)
                    .padding(.bottom, 20)

                Text("Analyse Your Expenditure")
                    .font(.system(.title2, design: .rounded).weight(.medium))
//                    .font(.system(size: 23.5, weight: .medium, design: .rounded))
                    .foregroundColor(Color.PrimaryText.opacity(0.8))
                    .multilineTextAlignment(.center)

                Text("As transactions start piling up")
                    .font(.system(.body, design: .rounded).weight(.medium))
//                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(Color.SubtitleText.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            .frame(height: 250, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            .background(Color.PrimaryBackground)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

        } else {
            VStack(spacing: 5) {
                HStack {
                    Text("Insights")
                        .font(.system(.title, design: .rounded).weight(.semibold))
//                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .accessibility(addTraits: .isHeader)
                    Spacer()

                    Button {
                        showTimeMenu = true
                    } label: {
                        HStack(spacing: 4.5) {
                            Text(chartTypeString)
                                .font(.system(.body, design: .rounded).weight(.medium))

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(.caption, design: .rounded).weight(.medium))
//                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(3)
                        .padding(.horizontal, 6)
//                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(Color.PrimaryText.opacity(0.9))
                        .background(Color.Outline, in: RoundedRectangle(cornerRadius: 6))
//                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.Outline, lineWidth: 1.3))
                    }
                    .popover(present: $showTimeMenu, attributes: {
                        $0.position = .absolute(
                            originAnchor: .bottomRight,
                            popoverAnchor: .topRight
                        )
                        $0.rubberBandingMode = .none
                        $0.sourceFrameInset = UIEdgeInsets(top: 0, left: 0, bottom: -10, right: 0)
                        $0.presentation.animation = .easeInOut(duration: 0.2)
                        $0.dismissal.animation = .easeInOut(duration: 0.3)
                    }) {
                        ChartTimePickerView(showMenu: $showTimeMenu)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 20)

                if chartType == 1 {
                    WeekGraphView()
                        .id(refreshID)
                } else if chartType == 2 {
                    MonthGraphView()
                        .id(refreshID)
                } else if chartType == 3 {
                    YearGraphView()
                        .id(refreshID)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.PrimaryBackground)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .onReceive(self.didSave) { _ in
                self.refreshID = UUID()
            }
        }
    }
}

struct HorizontalPieChartView: View {
    @FetchRequest private var allCategories: FetchedResults<Category>
    @FetchRequest private var transactions: FetchedResults<Transaction>

    var income: Bool
    var date: Date
    var total: Double {
        var holdingTotal = 0.0

        transactions.forEach { transaction in
            holdingTotal += transaction.amount
        }

        return holdingTotal
    }

    @Binding var chosenAmount: Double
    @Binding var chosenName: String

    @Binding var categoryFilterMode: Bool
    @Binding var categoryFilter: Category?
    @Binding var selectedDate: Date?

    var categories: [PowerCategory] {
        var holding = [PowerCategory]()

        for category in allCategories {
            var holdingTotal = 0.0

            transactions.forEach { transaction in
                if transaction.category == category {
                    holdingTotal += transaction.wrappedAmount
                }
            }

            if holdingTotal == 0 {
                continue
            }

            let newCategory = PowerCategory(id: category.id ?? UUID(), category: category, percent: holdingTotal / total)

            holding.append(newCategory)
        }

        holding.sort(by: { lhs, rhs in
            lhs.percent > rhs.percent
        })

        return holding
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                HStack(spacing: proxy.size.width * 0.015) {
                    ForEach(categories) { category in
                        if category.percent < 0.005 {
                            EmptyView()
                        } else {
                            AnimatedHorizontalBarGraph(category: category, index: categories.firstIndex(of: category) ?? 0)
                                .frame(width: (proxy.size.width * (1.0 - (0.015 * Double(categories.count - 1)))) * category.percent)
                                .onTapGesture {
                                    withAnimation(.easeIn(duration: 0.2)) {
                                        if categoryFilter == category.category {
                                            selectedDate = nil
                                            categoryFilterMode = false
                                            categoryFilter = nil
                                        } else {
                                            selectedDate = nil
                                            categoryFilterMode = true
                                            categoryFilter = category.category
                                            chosenAmount = category.percent * total
                                            chosenName = category.category.wrappedName
                                        }
                                    }
                                }
                                .opacity(categoryFilterMode ? (categoryFilter == category.category ? 1 : 0.5) : 1)
                                .overlay {
                                    if categoryFilterMode && categoryFilter == category.category {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(Color.DarkBackground, lineWidth: 1.5)
                                    }
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 28)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 11) {
                    ForEach(categories, id: \.self) { category in
                        HStack(spacing: 9) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(category.category.income ? Color(hex: Color.colorArray[categories.firstIndex(of: category) ?? 0]) : Color(hex: category.category.wrappedColour))
                                .frame(width: 9, height: 9)
                            Text(category.category.wrappedName)
                                .font(.system(.callout, design: .rounded).weight(.semibold))
//                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.PrimaryText)
                                .padding(.trailing, 1)

                            if category.percent != 1 {
                                Text("\(category.percent * 100, specifier: "%.1f")%")
                                    .font(.system(.subheadline, design: .rounded))
//                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.SubtitleText)
                            } else {
                                Text("\(category.percent * 100, specifier: "%.0f")%")
                                    .font(.system(.subheadline, design: .rounded))
//                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.SubtitleText)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background {
                            if categoryFilterMode && categoryFilter == category.category {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.SecondaryBackground)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeIn(duration: 0.2)) {
                                if categoryFilter == category.category {
                                    selectedDate = nil
                                    categoryFilterMode = false
                                    categoryFilter = nil
                                } else {
                                    selectedDate = nil
                                    categoryFilterMode = true
                                    categoryFilter = category.category
                                    chosenAmount = category.percent * total
                                    chosenName = category.category.wrappedName
                                }
                            }
                        }
                        .opacity(categoryFilterMode ? (categoryFilter == category.category ? 1 : 0.5) : 1)
                    }
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    init(date: Date, categoryFilter: Binding<Category?>?, categoryFilterMode: Binding<Bool>, selectedDate: Binding<Date?>?, chosenAmount: Binding<Double>, chosenName: Binding<String>, type: ChartTimeFrame, income: Bool) {
        self.date = date
        self.income = income
        _categoryFilter = categoryFilter ?? Binding.constant(nil)
        _categoryFilterMode = categoryFilterMode
        _selectedDate = selectedDate ?? Binding.constant(nil)
        _chosenName = chosenName
        _chosenAmount = chosenAmount

        // fetching categories

        _allCategories = FetchRequest<Category>(sortDescriptors: [], predicate: NSPredicate(format: "income = %d", income))

        // fetching transactions

        let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), date as CVarArg)
        let incomePredicate = NSPredicate(format: "income = %d", income)

        let endPredicate: NSPredicate

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        switch type {
        case .week:
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .weekOfYear) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .day, value: 7, to: date) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        case .month:
            let next = calendar.date(byAdding: .month, value: 1, to: date) ?? Date.now

            if next > Date.now {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        case .year:
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .year) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .year, value: 1, to: date) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        }

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, incomePredicate])

        _transactions = FetchRequest<Transaction>(sortDescriptors: [], predicate: andPredicate)
    }
}

struct FilteredCategoryInsightsView: View {
    @SectionedFetchRequest<Date?, Transaction> private var transactions: SectionedFetchResults<Date?, Transaction>

    var body: some View {
        VStack(spacing: 30) {
            if transactions.count == 0 {
                NoResultsView(fullscreen: false)
            }

            ListView(transactions: _transactions)
        }
        .frame(maxHeight: .infinity)
    }

    init(category: Category?, date: Date, type: ChartTimeFrame) {
        if let unwrappedCategory = category {
            let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), date as CVarArg)
            let categoryPredicate = NSPredicate(format: "%K == %@", #keyPath(Transaction.category), unwrappedCategory)
            let incomePredicate = NSPredicate(format: "income = %d", unwrappedCategory.income)

            let endPredicate: NSPredicate

            var calendar = Calendar(identifier: .gregorian)

            calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
            calendar.minimumDaysInFirstWeek = 4

            switch type {
            case .week:
                if calendar.isDate(date, equalTo: Date.now, toGranularity: .weekOfYear) {
                    endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
                } else {
                    let next = calendar.date(byAdding: .day, value: 7, to: date) ?? Date.now
                    endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
                }
            case .month:
                if calendar.isDate(date, equalTo: Date.now, toGranularity: .month) {
                    endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
                } else {
                    let next = calendar.date(byAdding: .month, value: 1, to: date) ?? Date.now
                    endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
                }
            case .year:
                if calendar.isDate(date, equalTo: Date.now, toGranularity: .year) {
                    endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
                } else {
                    let next = calendar.date(byAdding: .year, value: 1, to: date) ?? Date.now
                    endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
                }
            }

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, categoryPredicate, incomePredicate])

            _transactions = SectionedFetchRequest<Date?, Transaction>(sectionIdentifier: \.day, sortDescriptors: [
                SortDescriptor(\.day, order: .reverse),
                SortDescriptor(\.date, order: .reverse)
            ], predicate: andPredicate)

        } else {
            _transactions = SectionedFetchRequest<Date?, Transaction>(sectionIdentifier: \.day, sortDescriptors: [
                SortDescriptor(\.day, order: .reverse),
                SortDescriptor(\.date, order: .reverse)
            ])
        }
    }
}

struct FilteredDateInsightsView: View {
    @FetchRequest private var transactions: FetchedResults<Transaction>

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @AppStorage("swapTimeLabel", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var swapTimeLabel: Bool = false
    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            if transactions.count == 0 {
                NoResultsView(fullscreen: false)
            }
            ForEach(transactions) { transaction in
                SingleTransactionView(transaction: transaction, showCents: showCents, currencySymbol: currencySymbol, currency: currency, swapTimeLabel: swapTimeLabel, future: false)
            }
        }
        .frame(maxHeight: .infinity)
    }

    init(date: Date, income: Bool) {
        let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), date as CVarArg)

        let endPredicate: NSPredicate

        let calendar = Calendar.current

        if calendar.isDate(date, equalTo: Date.now, toGranularity: .day) {
            endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
        } else {
            let next = calendar.date(byAdding: .day, value: 1, to: date) ?? Date.now
            endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
        }

        let incomePredicate = NSPredicate(format: "income = %d", income)

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, incomePredicate, endPredicate])

        _transactions = FetchRequest<Transaction>(sortDescriptors: [
            SortDescriptor(\.date, order: .reverse)
        ], predicate: andPredicate)
    }
}

struct FilteredInsightsView: View {
    @SectionedFetchRequest<Date?, Transaction> private var transactions: SectionedFetchResults<Date?, Transaction>

    var body: some View {
        VStack(spacing: 30) {
            if transactions.count == 0 {
                NoResultsView(fullscreen: false)
            }

            ListView(transactions: _transactions)
        }
        .frame(maxHeight: .infinity)
    }

    init(startDate: Date, income: Bool? = nil, type: Int) {
        let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), startDate as CVarArg)

        let endPredicate: NSPredicate

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        if type == 1 {
            if calendar.isDate(startDate, equalTo: Date.now, toGranularity: .weekOfYear) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .day, value: 7, to: startDate) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        } else if type == 2 {
            if calendar.isDate(startDate, equalTo: Date.now, toGranularity: .month) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .month, value: 1, to: startDate) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        } else {
            if calendar.isDate(startDate, equalTo: Date.now, toGranularity: .year) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .year, value: 1, to: startDate) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        }

        let andPredicate: NSCompoundPredicate

        if let unwrappedIncome = income {
            let incomePredicate = NSPredicate(format: "income = %d", unwrappedIncome)
            andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, incomePredicate])

        } else {
            andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])
        }

        _transactions = SectionedFetchRequest<Date?, Transaction>(sectionIdentifier: \.day, sortDescriptors: [
            SortDescriptor(\.day, order: .reverse),
            SortDescriptor(\.date, order: .reverse)
        ], predicate: andPredicate)
    }
}

struct SingleGraphView: View {
    @EnvironmentObject var dataController: DataController
    var date: Date
    let type: Int

    @Binding var categoryFilterMode: Bool
    @Binding var selectedDate: Date?

    @AppStorage("incomeTracking", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var incomeTracking: Bool = true
    let language = Locale.current.languageCode

    var selectedDateString: String {
        if let unwrappedDate = selectedDate {
            let dateFormatter = DateFormatter()

            if type == 3 {
                dateFormatter.dateFormat = "MMM yyyy"
            } else {
                dateFormatter.dateFormat = "d MMM yyyy"
            }

            if language == "ru" {
                return dateFormatter.string(from: unwrappedDate)
            } else {
                return dateFormatter.string(from: unwrappedDate).uppercased()
            }
        } else {
            return ""
        }
    }

    @State var selectedDateAmount: Double = 0

    var currencySymbol: String
    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var showCents: Bool

    @AppStorage("firstDayOfMonth", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var firstDayOfMonth: Int = 1

    var dateString: String {
        let dateFormatter = DateFormatter()

        if type == 1 {
            dateFormatter.dateFormat = "d MMM"
            let endComponents = DateComponents(day: 7, second: -1)
            let endWeekDate = Calendar.current.date(byAdding: endComponents, to: date) ?? Date.now
            if language == "ru" {
                return dateFormatter.string(from: date) + " - " + dateFormatter.string(from: endWeekDate)
            } else {
                return dateFormatter.string(from: date).uppercased() + " - " + dateFormatter.string(from: endWeekDate).uppercased()
            }

        } else if type == 2 {
            if firstDayOfMonth == 1 {
                dateFormatter.dateFormat = "MMM yyyy"
            } else {
                dateFormatter.dateFormat = "d MMM"
                let endComponents = DateComponents(month: 1, second: -1)
                let endMonthDate = Calendar.current.date(byAdding: endComponents, to: date) ?? Date.now
                if language == "ru" {
                    return dateFormatter.string(from: date) + " - " + dateFormatter.string(from: endMonthDate)
                } else {
                    return dateFormatter.string(from: date).uppercased() + " - " + dateFormatter.string(from: endMonthDate).uppercased()
                }
            }
        } else if type == 3 {
            dateFormatter.dateFormat = "yyyy"
        }

        if language == "ru" {
            return dateFormatter.string(from: date)
        } else {
            return dateFormatter.string(from: date).uppercased()
        }
    }

    var selectedCategoryName: String
    var selectedCategoryAmount: Double

    @Binding var income: Bool
    @Binding var incomeFiltering: Bool

    let totalIncome: Double
    let totalSpent: Double
    let totalNet: Double
    let netPositive: Bool
    let currentNet: Double
    let lastNet: Double
    let average: Double

    var incomeAverage: Double {
        let loaded = dataController.getInsights(type: type, date: date, income: income)
        return loaded.average
    }

    var percentageDifference: String {
        if lastNet == 0 {
            return ""
        }

        let percentage: Double = ((currentNet - lastNet) / abs(lastNet)) * 100

        let roundedPercentage = Int(ceil(percentage))

        if currentNet > lastNet {
            return "+\(roundedPercentage)%"
        } else {
            return "\(roundedPercentage)%"
        }
    }

    var showPercentage: Bool {
        let amountText = stringConverter(amount: totalNet)
        let supplementalText: String

        if categoryFilterMode {
            supplementalText = stringConverter(amount: selectedCategoryAmount)
        } else if selectedDate != nil {
            supplementalText = stringConverter(amount: selectedDateAmount)
        } else if incomeFiltering {
            supplementalText = stringConverter(amount: incomeAverage)
        } else {
            supplementalText = stringConverter(amount: average)
        }

        let currencyWidth = currencySymbol.widthOfRoundedString(size: 20, weight: .regular)

        let totalWidth = amountText.widthOfRoundedString(size: 30, weight: .medium) + 1.3 + currencyWidth
        let averageWidth = supplementalText.widthOfRoundedString(size: 30, weight: .medium) + 1.3 + currencyWidth
        let percentageWidth = percentageDifference.widthOfRoundedString(size: 13, weight: .medium) + 10

        let screenWidth = UIScreen.main.bounds.width - 60

        return totalWidth + averageWidth + percentageWidth + 40 < screenWidth
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 1.3) {
                    Text(dateString)
                        .lineLimit(1)
                        .font(.system(.callout, design: .rounded).weight(.semibold))
//                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                        .layoutPriority(1)

                    HStack(spacing: 10) {
                        InsightsDollarView(amount: totalNet, currencySymbol: currencySymbol, showCents: showCents, net: netPositive)
                            .layoutPriority(1)

                        if showPercentage {
                            Text(percentageDifference)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(currentNet < lastNet ? Color.AlertRed : Color.IncomeGreen)
                                .padding(3)
                                .padding(.horizontal, 3)
                                .background(currentNet < lastNet ? Color.AlertRed.opacity(0.23) : Color.IncomeGreen.opacity(0.23), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .opacity(currentNet == 0 || lastNet == 0 ? 0 : 1)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if categoryFilterMode {
                    VStack(alignment: .trailing, spacing: 1.3) {
                        Text(selectedCategoryName.uppercased())
                            .lineLimit(1)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
//                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)

                        InsightsDollarView(amount: selectedCategoryAmount, currencySymbol: currencySymbol, showCents: showCents)
                            .layoutPriority(1)
                    }
                } else if selectedDate != nil {
                    VStack(alignment: .trailing, spacing: 1.3) {
                        Text(selectedDateString)
                            .lineLimit(1)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
//                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                        InsightsDollarView(amount: selectedDateAmount, currencySymbol: currencySymbol, showCents: showCents)
                            .layoutPriority(1)
                    }
                } else if incomeFiltering {
                    VStack(alignment: .trailing, spacing: 1.3) {
                        Text(type == 3 ? (income ? "INCOME/MTH" : "SPENT/MTH") : (income ? "INCOME/DAY" : "SPENT/DAY"))
                            .lineLimit(1)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
//                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                        InsightsDollarView(amount: incomeAverage, currencySymbol: currencySymbol, showCents: showCents)
                            .layoutPriority(1)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 1.3) {
                        Text(type == 3 ? "AVG/MTH" : "AVG/DAY")
                            .lineLimit(1)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
//                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                        InsightsDollarView(amount: average, currencySymbol: currencySymbol, showCents: showCents, net: netPositive)
                            .layoutPriority(1)
                    }
                }
            }
            .padding(.bottom, 5)
            .onTapGesture {
                withAnimation(.easeIn(duration: 0.2)) {
                    selectedDate = nil
                }
            }

            if incomeTracking {
                HStack(spacing: 11) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.IncomeGreen)
                            .padding(5)
                            .frame(width: 30, height: 30)
                            .background(Color.IncomeGreen.opacity(0.23), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.horizontal, 3)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("Income")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
//                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .foregroundColor(Color.SubtitleText)

                            Text(stringGenerator(amount: totalIncome))
                                .font(.system(.title3, design: .rounded).weight(.medium))
//                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(Color.PrimaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            if incomeFiltering && income {
                                incomeFiltering = false
                            } else {
                                income = true
                                incomeFiltering = true
                            }
                        }
                    }
                    .background(Color.SecondaryBackground.opacity(0.8), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        if income && incomeFiltering {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.SubtitleText.opacity(0.7), lineWidth: 1.95)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.AlertRed)
                            .padding(5)
                            .frame(width: 30, height: 30)
                            .background(Color.AlertRed.opacity(0.23), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.horizontal, 3)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("Expenses")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
//                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .foregroundColor(Color.SubtitleText)

                            Text(stringGenerator(amount: totalSpent))
                                .font(.system(.title3, design: .rounded).weight(.medium))
//                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(Color.PrimaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            if incomeFiltering && !income {
                                incomeFiltering = false
                            } else {
                                income = false
                                incomeFiltering = true
                            }
                        }
                    }
                    .background(Color.SecondaryBackground.opacity(0.8), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        if !income && incomeFiltering {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.SubtitleText.opacity(0.7), lineWidth: 1.95)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 13)
            }

            if incomeFiltering {
                if type == 1 {
                    SingleWeekBarGraphView(week: date, date: $selectedDate, mode: $categoryFilterMode, amount: $selectedDateAmount, dataController: dataController, income: income)
                } else if type == 2 {
                    SingleMonthBarGraphView(month: date, date: $selectedDate, mode: $categoryFilterMode, amount: $selectedDateAmount, dataController: dataController, income: income)
                } else if type == 3 {
                    SingleYearBarGraphView(year: date, date: $selectedDate, mode: $categoryFilterMode, amount: $selectedDateAmount, dataController: dataController, income: income)
                }
            }
        }
    }

    func stringGenerator(amount: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = currency

        if showCents && amount < 1000 {
            numberFormatter.maximumFractionDigits = 2
        } else {
            numberFormatter.maximumFractionDigits = 0
        }

        return numberFormatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    func stringConverter(amount: Double) -> String {
        if showCents && amount < 100 {
            return String(format: "%.2f", amount)
        } else {
            return String(format: "%.0f", amount)
        }
    }

    init(showingDate: Date, date: Binding<Date?>?, mode: Binding<Bool>, categoryName: String, categoryAmount: Double, currencySymbol: String, showCents: Bool, dataController: DataController, income: Binding<Bool>, incomeFiltering: Binding<Bool>, type: Int) {
        _selectedDate = date ?? Binding.constant(nil)
        _categoryFilterMode = mode
        _income = income
        _incomeFiltering = incomeFiltering
        self.date = showingDate
        selectedCategoryName = categoryName
        selectedCategoryAmount = categoryAmount
        self.currencySymbol = currencySymbol
        self.showCents = showCents
        self.type = type

        let loaded = dataController.getInsightsSummary(type: type, date: showingDate)

        totalIncome = loaded.income
        totalSpent = loaded.spent
        netPositive = loaded.positive
        totalNet = loaded.net
        average = loaded.average

        if loaded.positive {
            currentNet = loaded.net
        } else {
            currentNet = -loaded.net
        }

        let lastDate: Date

        if type == 1 {
            lastDate = Calendar.current.date(byAdding: .day, value: -7, to: showingDate) ?? Date.now
        } else if type == 2 {
            lastDate = Calendar.current.date(byAdding: .month, value: -1, to: showingDate) ?? Date.now
        } else {
            lastDate = Calendar.current.date(byAdding: .year, value: -1, to: showingDate) ?? Date.now
        }

        let lastDateData = dataController.getInsightsSummary(type: type, date: lastDate)

        if lastDateData.positive {
            lastNet = lastDateData.net
        } else {
            lastNet = -lastDateData.net
        }
    }
}

struct WeekGraphView: View {
    @EnvironmentObject var dataController: DataController

    private var didSave = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
    @State private var refreshID = UUID()

    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.day)
    ]) private var transactions: FetchedResults<Transaction>

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @State var categoryFilterMode = false
    @State var categoryFilter: Category?

    @State var selectedDate: Date?

    var startOfCurrentWeek: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")?.integer(forKey: "firstWeekday") ?? 0
        calendar.minimumDaysInFirstWeek = 4

        let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date.now)

        return calendar.date(from: dateComponents) ?? Date.now
    }

    // start of week of final transaction
    var startOfLastWeek: Date {
        if transactions.isEmpty {
            return Date.now
        } else {
            var calendar = Calendar(identifier: .gregorian)
            calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")?.integer(forKey: "firstWeekday") ?? 0
            calendar.minimumDaysInFirstWeek = 4

            if let date = transactions[0].day {
                let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: date)

                return calendar.date(from: dateComponents) ?? Date.now
            } else {
                return Date.now
            }
        }
    }

    var swipeStrings: (backward: String, forward: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"

        let calendar = Calendar.current

        let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: showingWeek) ?? Date.now
        let startOfNextWeek = calendar.date(byAdding: .day, value: 7, to: showingWeek) ?? Date.now

        return (dateFormatter.string(from: startOfLastWeek), dateFormatter.string(from: startOfNextWeek))
    }

    @State private var offset: CGFloat = 0
    @State private var changeDate: Bool = false
    @GestureState var isDragging = false
    var changeTime: Bool {
        if offset < -(UIScreen.main.bounds.width * 0.25) && showingWeek != startOfCurrentWeek {
            return true
        } else if offset > (UIScreen.main.bounds.width * 0.25) && showingWeek != startOfLastWeek {
            return true
        } else {
            return false
        }
//
//        return abs(offset) > UIScreen.main.bounds.width * 0.3
    }

    @State var showingWeek = Date.now

    @State private var refreshID1 = UUID()

    @State var chosenCategoryName = ""
    @State var chosenCategoryAmount = 0.0

    @AppStorage("insightsViewIncomeFiltering", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var income: Bool = true
    @AppStorage("incomeTracking", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var incomeTracking: Bool = true

//    @Environment(\.dynamicTypeMultiplier) var multiplier

    @State var incomeFiltering: Bool = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    SingleGraphView(showingDate: showingWeek, date: $selectedDate, mode: $categoryFilterMode, categoryName: chosenCategoryName, categoryAmount: chosenCategoryAmount, currencySymbol: currencySymbol, showCents: showCents, dataController: dataController, income: $income, incomeFiltering: $incomeFiltering, type: 1)
                        .drawingGroup()
                        .id(refreshID)
                        .onAppear {
                            showingWeek = startOfCurrentWeek
                        }
                        .offset(x: offset)

                    if !changeDate {
                        HStack {
                            if showingWeek != startOfLastWeek {
                                SwipeArrowView(left: true, swipeString: swipeStrings.backward.uppercased(), changeTime: changeTime)
                                .offset(x: -100)
                                .offset(x: min(100, offset))
                            } else {
                                SwipeEndView(left: true)
                                .offset(x: -120)
                                .offset(x: min(120, offset))
                            }

                            Spacer()
                        }

                        HStack {
                            Spacer()

                            if showingWeek != startOfCurrentWeek {
                                SwipeArrowView(left: false, swipeString: swipeStrings.forward.uppercased(), changeTime: changeTime)
                                .offset(x: 100)
                                .offset(x: max(-100, offset))
                            } else {
                                SwipeEndView(left: false)
                                .offset(x: 120)
                                .offset(x: max(-120, offset))
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 30)
                .simultaneousGesture(
                    DragGesture()
                        .updating($isDragging, body: { _, state, _ in
                            state = true
                        })
                        .onChanged { value in
                            withAnimation {
                                if value.translation.width < 0, showingWeek != startOfCurrentWeek {
                                    offset = value.translation.width * 0.9
                                } else if value.translation.width < 0, showingWeek == startOfCurrentWeek {
                                    offset = value.translation.width * 0.5
                                } else if value.translation.width > 0, showingWeek != startOfLastWeek {
                                    offset = value.translation.width * 0.9
                                } else if value.translation.width > 0, showingWeek == startOfLastWeek {
                                    offset = value.translation.width * 0.5
                                }
                            }
                        }.onEnded { _ in
                            if changeTime {
                                if offset < 0, showingWeek != startOfCurrentWeek {
                                    changeDate = true

                                    offset = UIScreen.main.bounds.width

                                    showingWeek = Calendar.current.date(byAdding: .day, value: 7, to: showingWeek) ?? Date.now

                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        offset = 0
                                    }
                                } else if offset > 0, showingWeek != startOfLastWeek {
                                    changeDate = true

                                    offset = -UIScreen.main.bounds.width

                                    showingWeek = Calendar.current.date(byAdding: .day, value: -7, to: showingWeek) ?? Date.now

                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        offset = 0
                                    }
                                }

                                withAnimation(.easeInOut(duration: 0.3)) {
                                    offset = 0
                                }

                                changeDate = false
                            }
                        }
                )
                .onChange(of: changeTime) { _ in
                    if changeTime {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onChange(of: isDragging) { _ in
                    if !isDragging && !changeDate {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = 0
                        }
                    }
                }
                .animation(.easeInOut, value: changeTime)
                .onChange(of: showingWeek) { _ in
                    selectedDate = nil
                    categoryFilterMode = false
                    refreshID1 = UUID()
                }
                .onChange(of: income) { _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .onChange(of: incomeFiltering) { _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
//                .frame(height: getGraphHeight(incomeTracking: incomeTracking, incomeFiltering: incomeFiltering, multiplier: multiplier), alignment: .top)
                .padding(.bottom, incomeFiltering ? 5 : 20)

                if selectedDate == nil && incomeFiltering {
                    HorizontalPieChartView(date: showingWeek, categoryFilter: $categoryFilter, categoryFilterMode: $categoryFilterMode, selectedDate: $selectedDate, chosenAmount: $chosenCategoryAmount, chosenName: $chosenCategoryName, type: .week, income: income)
                        .padding(.horizontal, 30)
                        .id(refreshID1)
                }

                Group {
                    if !incomeFiltering {
                        FilteredInsightsView(startDate: showingWeek, type: 1)
                            .padding(.bottom, 70)
                    } else {
                        if selectedDate != nil {
                            FilteredDateInsightsView(date: selectedDate ?? Date.now, income: income)
                                .padding(.bottom, 70)

                        } else if categoryFilterMode {
                            FilteredCategoryInsightsView(category: categoryFilter, date: showingWeek, type: .week)
                                .padding(.bottom, 70)
                        } else {
                            FilteredInsightsView(startDate: showingWeek, income: income, type: 1)
                                .padding(.bottom, 70)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .onTapGesture {
                    selectedDate = nil
                    categoryFilterMode = false
                }
            }
        }
        .onReceive(self.didSave) { _ in
            self.refreshID = UUID()
            self.refreshID1 = UUID()
        }
    }
}

struct AverageLineView: View {
    var getMax: Int
    var average: Double

    @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated: Bool = true
    @State var showLine: Bool = false
    @State var offset: CGFloat = barHeight - 10

    var body: some View {
        HStack(spacing: 2) {
            PencilView(text: getAverageText(average: average))

            Line()
                .stroke(Color.SubtitleText, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5]))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .opacity(showLine ? 1 : 0)
        .offset(y: offset)
        .opacity((average / Double(getMax)) < 0.1 || (average / Double(getMax)) > 0.9 ? 0 : 1)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if !animated {
                    showLine = true
                } else {
                    withAnimation {
                        showLine = true
                    }
                }
            }
        }
        .onChange(of: showLine) { newValue in
            if newValue {
                if !animated {
                    offset = getOffset(maxi: getMax, average: average)
                } else {
                    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                        offset = getOffset(maxi: getMax, average: average)
                    }
                }
            }
        }
    }
}

struct SingleWeekBarGraphView: View {
    @Binding var selectedDate: Date?
    @Binding var categoryFilterMode: Bool
    @Binding var selectedDateAmount: Double

    var daysOfWeek = [Date]()

    var dayDictionary = [Date: Double]()

    var max: Double = 0
    var weekTotal: Double = 0
    var weekAverage: Double = 0
    var actualDays: Int = 0

    var getMax: Int {
        let maximum = max * 1.1

        return Int(ceil(maximum / 10) * 10)
    }

    var body: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top, spacing: 8) {
                // axes
                VStack(alignment: .leading) {
                    Text(getMaxText(maxi: getMax))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.SubtitleText)

                    Spacer()

                    Text("0")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                }
                .frame(height: barHeight)
                .padding(.trailing, 3)

                // bars
                HStack(spacing: 7) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        VStack(spacing: 5) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.SecondaryBackground)
                                    .frame(height: barHeight)

                                AnimatedBarGraph(index: daysOfWeek.firstIndex(of: day) ?? 0)
                                    .frame(height: getBarHeight(point: dayDictionary[day] ?? 0, maxi: getMax))
                                    .opacity(selectedDate == nil ? 1 : (selectedDate == day ? 1 : 0.4))
                            }

                            Text(getWeekday(day: day).prefix(1))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color.SubtitleText)
                        }
                        .opacity(day > Date.now ? 0.3 : 1)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(!(day > Date.now))
                        .onTapGesture {
                            withAnimation(.easeIn(duration: 0.2)) {
                                if selectedDate == day {
                                    selectedDate = nil
                                    categoryFilterMode = false
                                } else {
                                    selectedDate = day
                                    categoryFilterMode = false
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            // average line
            AverageLineView(getMax: getMax, average: weekAverage)
                .opacity(actualDays <= 1 ? 0 : 1)

        }
        .onChange(of: selectedDate) { _ in
            selectedDateAmount = dayDictionary[selectedDate ?? Date.now] ?? 0.0
        }
    }

    func getWeekday(day: Date) -> String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "EEE"

        return dateFormatter.string(from: day)
    }

    init(week: Date, date: Binding<Date?>?, mode: Binding<Bool>, amount: Binding<Double>, dataController: DataController, income: Bool) {
        _selectedDate = date ?? Binding.constant(nil)
        _categoryFilterMode = mode
        _selectedDateAmount = amount

        let loaded = dataController.getInsights(type: 1, date: week, income: income)

        daysOfWeek = loaded.dates
        dayDictionary = loaded.dateDictionary
        self.max = loaded.maximum
        weekTotal = loaded.amount
        weekAverage = loaded.average
        actualDays = loaded.numberOfDays
    }
}

struct MonthGraphView: View {
    @EnvironmentObject var dataController: DataController
    private var didSave = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
    @State private var refreshID = UUID()

    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.day)
    ]) private var transactions: FetchedResults<Transaction>

    @AppStorage("firstDayOfMonth", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var firstDayOfMonth: Int = 1

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @State var categoryFilterMode = false
    @State var categoryFilter: Category?

    @State var selectedDate: Date?

    var startOfCurrentMonth: Date {
        return getStartOfMonth(startDay: firstDayOfMonth)
//        let calendar = Calendar(identifier: .gregorian)
//
//        let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)
//
//        return  calendar.date(from: dateComponents) ?? Date.now
    }

    // start of month of the earliest transaction
    var startOfLastMonth: Date {
        if transactions.isEmpty {
            return Date.now
        } else {
            let date = transactions[0].day ?? Date.now

            return calculateStartOfMonthPeriod(earliestDate: date, startOfMonthDay: firstDayOfMonth)
//
//            let dateComponents = calendar.dateComponents([.month, .year], from: date)
//
//            return  calendar.date(from: dateComponents) ?? Date.now
        }
    }

    var swipeStrings: (backward: String, forward: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yy"

        let calendar = Calendar.current

        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: showingMonth) ?? Date.now
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: showingMonth) ?? Date.now

        return (dateFormatter.string(from: startOfLastMonth), dateFormatter.string(from: startOfNextMonth))
    }

    @State private var offset: CGFloat = 0
    @State private var changeDate: Bool = false
    @GestureState var isDragging = false
    var changeTime: Bool {
        if offset < -(UIScreen.main.bounds.width * 0.25) && showingMonth != startOfCurrentMonth {
            return true
        } else if offset > (UIScreen.main.bounds.width * 0.25) && showingMonth != startOfLastMonth {
            return true
        } else {
            return false
        }
//
//        return abs(offset) > UIScreen.main.bounds.width * 0.3
    }

    @State var showingMonth = Date.now

    @State private var refreshID1 = UUID()

    @State var chosenCategoryName = ""
    @State var chosenCategoryAmount = 0.0

    @AppStorage("insightsViewIncomeFiltering", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var income: Bool = true
    @AppStorage("incomeTracking", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var incomeTracking: Bool = true

//    @Environment(\.dynamicTypeMultiplier) var multiplier

    @State var incomeFiltering: Bool = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    SingleGraphView(showingDate: showingMonth, date: $selectedDate, mode: $categoryFilterMode, categoryName: chosenCategoryName, categoryAmount: chosenCategoryAmount, currencySymbol: currencySymbol, showCents: showCents, dataController: dataController, income: $income, incomeFiltering: $incomeFiltering, type: 2)
                        .drawingGroup()
                        .id(refreshID)
                        .onAppear {
                            showingMonth = startOfCurrentMonth
                        }
                        .offset(x: offset)

                    if !changeDate {
                        HStack {
                            if showingMonth != startOfLastMonth {
                                SwipeArrowView(left: true, swipeString: swipeStrings.backward.uppercased(), changeTime: changeTime)
                                .offset(x: -100)
                                .offset(x: min(100, offset))
                            } else {
                                SwipeEndView(left: true)
                                .offset(x: -120)
                                .offset(x: min(120, offset))
                            }

                            Spacer()
                        }

                        HStack {
                            Spacer()

                            if showingMonth != startOfCurrentMonth {
                                SwipeArrowView(left: false, swipeString: swipeStrings.forward.uppercased(), changeTime: changeTime)
                                .offset(x: 100)
                                .offset(x: max(-100, offset))
                            } else {
                                SwipeEndView(left: false)
                                .offset(x: 120)
                                .offset(x: max(-120, offset))
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 30)
                .simultaneousGesture(
                    DragGesture()
                        .updating($isDragging, body: { _, state, _ in
                            state = true
                        })
                        .onChanged { value in
                            withAnimation {
                                if value.translation.width < 0, showingMonth != startOfCurrentMonth {
                                    offset = value.translation.width * 0.9
                                } else if value.translation.width < 0, showingMonth == startOfCurrentMonth {
                                    offset = value.translation.width * 0.5
                                } else if value.translation.width > 0, showingMonth != startOfLastMonth {
                                    offset = value.translation.width * 0.9
                                } else if value.translation.width > 0, showingMonth == startOfLastMonth {
                                    offset = value.translation.width * 0.5
                                }
                            }
                        }.onEnded { _ in
                            if changeTime {
                                if offset < 0, showingMonth != startOfCurrentMonth {
                                    changeDate = true

                                    offset = UIScreen.main.bounds.width

                                    showingMonth = Calendar.current.date(byAdding: .month, value: 1, to: showingMonth) ?? Date.now

                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        offset = 0
                                    }
                                } else if offset > 0, showingMonth != startOfLastMonth {
                                    changeDate = true

                                    offset = -UIScreen.main.bounds.width

                                    showingMonth = Calendar.current.date(byAdding: .month, value: -1, to: showingMonth) ?? Date.now

                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        offset = 0
                                    }
                                }

                                withAnimation(.easeInOut(duration: 0.3)) {
                                    offset = 0
                                }

                                changeDate = false
                            }
                        }
                )
                .onChange(of: changeTime) { _ in
                    if changeTime {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onChange(of: isDragging) { _ in
                    if !isDragging && !changeDate {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = 0
                        }
                    }
                }
                .animation(.easeInOut, value: changeTime)
                .onChange(of: showingMonth) { _ in
                    selectedDate = nil
                    categoryFilterMode = false
                    refreshID1 = UUID()
                }
                .onChange(of: income) { _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .onChange(of: incomeFiltering) { _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .padding(.bottom, incomeFiltering ? 5 : 20)

                if selectedDate == nil && incomeFiltering {
                    HorizontalPieChartView(date: showingMonth, categoryFilter: $categoryFilter, categoryFilterMode: $categoryFilterMode, selectedDate: $selectedDate, chosenAmount: $chosenCategoryAmount, chosenName: $chosenCategoryName, type: .month, income: income)
                        .padding(.horizontal, 30)
                        .id(refreshID1)
                }

                Group {
                    if !incomeFiltering {
                        FilteredInsightsView(startDate: showingMonth, type: 2)
                            .padding(.bottom, 70)
                    } else {
                        if selectedDate != nil {
                            FilteredDateInsightsView(date: selectedDate ?? Date.now, income: income)
                                .padding(.bottom, 70)

                        } else if categoryFilterMode {
                            FilteredCategoryInsightsView(category: categoryFilter, date: showingMonth, type: .month)
                                .padding(.bottom, 70)
                        } else {
                            FilteredInsightsView(startDate: showingMonth, income: income, type: 2)
                                .padding(.bottom, 70)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .onTapGesture {
                    selectedDate = nil
                    categoryFilterMode = false
                }
            }
        }
        .onReceive(self.didSave) { _ in
            self.refreshID = UUID()
            self.refreshID1 = UUID()
        }
    }
}

struct SingleMonthBarGraphView: View {
    @AppStorage("firstDayOfMonth", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var firstDayOfMonth: Int = 1

    @Binding var selectedDate: Date?
    @Binding var categoryFilterMode: Bool
    @Binding var selectedDateAmount: Double

    var daysOfMonth = [Date]()

    var dayDictionary = [Date: Double]()

    var max: Double = 0
    var monthTotal: Double = 0
    var monthAverage: Double = 0
    var actualDays: Int = 0

    var getMax: Int {
        let maximum = max * 1.1

        return Int(ceil(maximum / 10) * 10)
    }

    let numberArray = [1, 8, 15, 22, 29]

    var body: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top, spacing: 3) {
                // axes
                VStack(alignment: .leading) {
                    Text(getMaxText(maxi: getMax))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.SubtitleText)

                    Spacer()

                    Text("0")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.SubtitleText)

                }
                .frame(height: barHeight)
                .padding(.trailing, 3)

                // bars
                HStack(alignment: .top, spacing: 2) {
                    ForEach(daysOfMonth, id: \.self) { day in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.SecondaryBackground)
                                .frame(height: barHeight)
                                .zIndex(0)

                            AnimatedBarGraph(index: daysOfMonth.firstIndex(of: day) ?? 0)
                                .frame(height: getBarHeight(point: dayDictionary[day] ?? 0, maxi: getMax))
                                .opacity(selectedDate == nil ? 1 : (selectedDate == day ? 1 : 0.4))
                                .zIndex(0)
                                .overlay(alignment: .bottom) {
                                    if numberArray.contains(((daysOfMonth.firstIndex(of: day) ?? -1) + 1)) && firstDayOfMonth == 1 {
                                        Text("\((daysOfMonth.firstIndex(of: day) ?? -1) + 1)")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(Color.SubtitleText)
                                            .frame(width: 20, alignment: .center)
                                            .offset(y: 20)
                                    }
                                }
                        }
                        .padding(.bottom, firstDayOfMonth == 1 ? 22 : 0)
                        .opacity(day > Date.now ? 0.3 : 1)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(!(day > Date.now))
                        .onTapGesture {
                            withAnimation(.easeIn(duration: 0.2)) {
                                if selectedDate == day {
                                    selectedDate = nil
                                    categoryFilterMode = false
                                } else {
                                    selectedDate = day
                                    categoryFilterMode = false
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

            }
            .frame(maxWidth: .infinity)

            //                .frame(maxHeight: .infinity)

            // average line

            AverageLineView(getMax: getMax, average: monthAverage)
                .opacity(actualDays <= 1 ? 0 : 1)

        }
        .onChange(of: selectedDate) { _ in
            selectedDateAmount = dayDictionary[selectedDate ?? Date.now] ?? 0.0
        }
    }

    init(month: Date, date: Binding<Date?>?, mode: Binding<Bool>, amount: Binding<Double>, dataController: DataController, income: Bool) {
        _selectedDate = date ?? Binding.constant(nil)
        _categoryFilterMode = mode
        _selectedDateAmount = amount

        let loaded = dataController.getInsights(type: 2, date: month, income: income)

        daysOfMonth = loaded.dates
        dayDictionary = loaded.dateDictionary
        self.max = loaded.maximum
        monthTotal = loaded.amount
        monthAverage = loaded.average
        actualDays = loaded.numberOfDays
    }
}

struct YearGraphView: View {
    @EnvironmentObject var dataController: DataController
    private var didSave = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
    @State private var refreshID = UUID()

    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.day)
    ]) private var transactions: FetchedResults<Transaction>

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @State var categoryFilterMode = false
    @State var categoryFilter: Category?

    @State var selectedDate: Date?

    var startOfCurrentYear: Date {
        let calendar = Calendar(identifier: .gregorian)

        let dateComponents = calendar.dateComponents([.year], from: Date.now)

        return calendar.date(from: dateComponents) ?? Date.now
    }

    var startOfLastYear: Date {
        if transactions.isEmpty {
            return Date.now
        } else {
            let calendar = Calendar(identifier: .gregorian)

            let date = transactions[0].day ?? Date.now

            let dateComponents = calendar.dateComponents([.year], from: date)

            return calendar.date(from: dateComponents) ?? Date.now
        }
    }

    var swipeStrings: (backward: String, forward: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"

        let calendar = Calendar.current

        let startOfLastYear = calendar.date(byAdding: .year, value: -1, to: showingYear) ?? Date.now
        let startOfNextYear = calendar.date(byAdding: .year, value: 1, to: showingYear) ?? Date.now

        return (dateFormatter.string(from: startOfLastYear), dateFormatter.string(from: startOfNextYear))
    }

    @State private var offset: CGFloat = 0
    @State private var changeDate: Bool = false
    @GestureState var isDragging = false
    var changeTime: Bool {
        if offset < -(UIScreen.main.bounds.width * 0.25) && showingYear != startOfCurrentYear {
            return true
        } else if offset > (UIScreen.main.bounds.width * 0.25) && showingYear != startOfLastYear {
            return true
        } else {
            return false
        }
//
//        return abs(offset) > UIScreen.main.bounds.width * 0.3
    }

    @State var showingYear = Date.now

    @State private var refreshID1 = UUID()

    @State var chosenCategoryName = ""
    @State var chosenCategoryAmount = 0.0

    @AppStorage("insightsViewIncomeFiltering", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var income: Bool = true
    @AppStorage("incomeTracking", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var incomeTracking: Bool = true
//
//    @Environment(\.dynamicTypeMultiplier) var multiplier

    @State var incomeFiltering: Bool = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    SingleGraphView(showingDate: showingYear, date: $selectedDate, mode: $categoryFilterMode, categoryName: chosenCategoryName, categoryAmount: chosenCategoryAmount, currencySymbol: currencySymbol, showCents: showCents, dataController: dataController, income: $income, incomeFiltering: $incomeFiltering, type: 3)
                        .drawingGroup()
                        .id(refreshID)
                        .onAppear {
                            showingYear = startOfCurrentYear
                        }
                        .offset(x: offset)

                    if !changeDate {
                        HStack {
                            if showingYear != startOfLastYear {
                                SwipeArrowView(left: true, swipeString: swipeStrings.backward.uppercased(), changeTime: changeTime)
                                .offset(x: -100)
                                .offset(x: min(100, offset))
                            } else {
                                SwipeEndView(left: true)
                                .offset(x: -120)
                                .offset(x: min(120, offset))
                            }

                            Spacer()
                        }

                        HStack {
                            Spacer()

                            if showingYear != startOfCurrentYear {
                                SwipeArrowView(left: false, swipeString: swipeStrings.forward.uppercased(), changeTime: changeTime)
                                .offset(x: 100)
                                .offset(x: max(-100, offset))
                            } else {
                                SwipeEndView(left: false)
                                .offset(x: 120)
                                .offset(x: max(-120, offset))
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 30)
                .simultaneousGesture(
                    DragGesture()
                        .updating($isDragging, body: { _, state, _ in
                            state = true
                        })
                        .onChanged { value in
                            withAnimation {
                                if value.translation.width < 0, showingYear != startOfCurrentYear {
                                    offset = value.translation.width * 0.9
                                } else if value.translation.width < 0, showingYear == startOfCurrentYear {
                                    offset = value.translation.width * 0.5
                                } else if value.translation.width > 0, showingYear != startOfLastYear {
                                    offset = value.translation.width * 0.9
                                } else if value.translation.width > 0, showingYear == startOfLastYear {
                                    offset = value.translation.width * 0.5
                                }
                            }
                        }.onEnded { _ in
                            if changeTime {
                                if offset < 0, showingYear != startOfCurrentYear {
                                    changeDate = true

                                    offset = UIScreen.main.bounds.width

                                    showingYear = Calendar.current.date(byAdding: .year, value: 1, to: showingYear) ?? Date.now

                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        offset = 0
                                    }
                                } else if offset > 0, showingYear != startOfLastYear {
                                    changeDate = true

                                    offset = -UIScreen.main.bounds.width

                                    showingYear = Calendar.current.date(byAdding: .year, value: -1, to: showingYear) ?? Date.now

                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        offset = 0
                                    }
                                }

                                withAnimation(.easeInOut(duration: 0.3)) {
                                    offset = 0
                                }

                                changeDate = false
                            }
                        }
                )
                .onChange(of: changeTime) { _ in
                    if changeTime {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onChange(of: isDragging) { _ in
                    if !isDragging && !changeDate {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = 0
                        }
                    }
                }
                .animation(.easeInOut, value: changeTime)
                .onChange(of: showingYear) { _ in
                    selectedDate = nil
                    categoryFilterMode = false
                    refreshID1 = UUID()
                }
                .onChange(of: income) { _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
                .onChange(of: incomeFiltering) { _ in
                    selectedDate = nil
                    categoryFilterMode = false
                }
//                .frame(height: getGraphHeight(incomeTracking: incomeTracking, incomeFiltering: incomeFiltering, multiplier: multiplier), alignment: .top)
                .padding(.bottom, incomeFiltering ? 5 : 20)

                if selectedDate == nil && incomeFiltering {
                    HorizontalPieChartView(date: showingYear, categoryFilter: $categoryFilter, categoryFilterMode: $categoryFilterMode, selectedDate: $selectedDate, chosenAmount: $chosenCategoryAmount, chosenName: $chosenCategoryName, type: .year, income: income)
                        .padding(.horizontal, 30)
                        .id(refreshID1)
                }

                Group {
                    if !incomeFiltering {
                        FilteredInsightsView(startDate: showingYear, type: 3)
                            .padding(.bottom, 70)
                    } else {
                        if selectedDate != nil {
                            FilteredInsightsView(startDate: selectedDate ?? Date.now, income: income, type: 2)
                                .padding(.bottom, 70)

                        } else if categoryFilterMode {
                            FilteredCategoryInsightsView(category: categoryFilter, date: showingYear, type: .year)
                                .padding(.bottom, 70)
                        } else {
                            FilteredInsightsView(startDate: showingYear, income: income, type: 3)
                                .padding(.bottom, 70)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .onTapGesture {
                    selectedDate = nil
                    categoryFilterMode = false
                }
            }
        }
        .onReceive(self.didSave) { _ in
            self.refreshID = UUID()
            self.refreshID1 = UUID()
        }
    }
}

struct SingleYearBarGraphView: View {
    @Binding var selectedDate: Date?
    @Binding var categoryFilterMode: Bool
    @Binding var selectedDateAmount: Double

    var monthsOfYear = [Date]()

    var monthDictionary = [Date: Double]()

    var max: Double = 0

    var getMax: Int {
        let maximum = max * 1.1

        return Int(ceil(maximum / 10) * 10)
    }

    var yearTotal: Double = 0
    var yearAverage: Double = 0
    var actualMonths: Int = 0
    var pastYearTotal: Double = 0

    let numberArray = [1, 4, 7, 10]
    let monthNames: [Int: String] = [1: "Jan", 4: "Apr", 7: "Jul", 10: "Oct"]

    var body: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top, spacing: 3) {
                // axes
                VStack(alignment: .leading) {
                    Text(getMaxText(maxi: getMax))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.SubtitleText)

                    Spacer()

                    Text("0")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.SubtitleText)

                }
                .frame(height: barHeight)
                .padding(.trailing, 3)

                // bars
                HStack(alignment: .top, spacing: 4) {
                    ForEach(monthsOfYear, id: \.self) { month in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.SecondaryBackground)
                                .frame(height: barHeight)
                                .zIndex(0)

                            AnimatedBarGraph(index: monthsOfYear.firstIndex(of: month) ?? 0)
                                .frame(height: getBarHeight(point: monthDictionary[month] ?? 0, maxi: getMax))
                                .opacity(selectedDate == nil ? 1 : (selectedDate == month ? 1 : 0.4))
                                .zIndex(0)
                                .overlay(alignment: .bottom) {
                                    if numberArray.contains(((monthsOfYear.firstIndex(of: month) ?? 0) + 1)) {
                                        Text(LocalizedStringKey(monthNames[((monthsOfYear.firstIndex(of: month) ?? 0) + 1)] ?? ""))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(Color.SubtitleText)
                                            .frame(width: 30)
                                            .offset(y: 20)
                                    }
                                }
                        }
                        .padding(.bottom, 22)
                        .opacity(month > Date.now ? 0.3 : 1)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(!(month > Date.now))
                        .onTapGesture {
                            withAnimation(.easeIn(duration: 0.2)) {
                                if selectedDate == month {
                                    selectedDate = nil
                                    categoryFilterMode = false
                                } else {
                                    selectedDate = month
                                    categoryFilterMode = false
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

            }
            .frame(maxWidth: .infinity)

            // average line

            AverageLineView(getMax: getMax, average: yearAverage)
                .opacity(actualMonths <= 1 ? 0 : 1)

        }
        .onChange(of: selectedDate) { _ in
            selectedDateAmount = monthDictionary[selectedDate ?? Date.now] ?? 0.0
        }
    }

    func getMonth(month: Date) -> String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "M"

        return dateFormatter.string(from: month)
    }

    init(year: Date, date: Binding<Date?>?, mode: Binding<Bool>, amount: Binding<Double>, dataController: DataController, income: Bool) {
        _selectedDate = date ?? Binding.constant(nil)
        _categoryFilterMode = mode
        _selectedDateAmount = amount

        let loaded = dataController.getInsights(type: 3, date: year, income: income)

        monthsOfYear = loaded.dates
        monthDictionary = loaded.dateDictionary
        self.max = loaded.maximum
        yearTotal = loaded.amount
        yearAverage = loaded.average
        actualMonths = loaded.numberOfDays
    }
}

func getMaxText(maxi: Int) -> String {
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

struct ChartTimePickerView: View {
    @Namespace var animation
    @State var timeframe = ChartTimeFrame.week
    @Binding var showMenu: Bool

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var colourScheme: Int = 0

    @AppStorage("chartTimeFrame", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var chartType = 1

    @Environment(\.colorScheme) var systemColorScheme

    var darkMode: Bool {
        (colourScheme == 0 && systemColorScheme == .dark) || colourScheme == 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(ChartTimeFrame.allCases, id: \.self) { time in
                HStack {
                    Text(LocalizedStringKey(time.rawValue))
                    Spacer()

                    if time == timeframe {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .padding(5)
                .background {
                    if time == timeframe {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(darkMode ? Color("AlwaysDarkSecondaryBackground") : Color("AlwaysLightSecondaryBackground"))
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if timeframe == time {
                        showMenu = false
                    } else {
                        withAnimation(.easeIn(duration: 0.15)) {
                            timeframe = time
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showMenu = false
                        }
                    }
                }
            }
        }
        .foregroundColor(darkMode ? Color("AlwaysLightBackground") : Color("AlwaysDarkBackground"))
        .padding(4)
        .frame(width: 120)
        .background(RoundedRectangle(cornerRadius: 9).fill(darkMode ? Color("AlwaysDarkBackground") : Color("AlwaysLightBackground")).shadow(color: darkMode ? Color.clear : Color.gray.opacity(0.25), radius: 6))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(darkMode ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
        .onChange(of: timeframe) { _ in
            if timeframe == .week {
                chartType = 1
            } else if timeframe == .month {
                chartType = 2
            } else if timeframe == .year {
                chartType = 3
            }
        }
        .onAppear {
            if chartType == 1 {
                timeframe = ChartTimeFrame.week
            } else if chartType == 2 {
                timeframe = ChartTimeFrame.month
            } else if chartType == 3 {
                timeframe = ChartTimeFrame.year
            }
        }
    }
}

struct AnimatedBarGraph: View {
    var index: Int

    @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated: Bool = true
    @State var showBar: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.DarkBackground)
                .frame(height: showBar ? nil : 0, alignment: .bottom)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if !animated {
                    showBar = true
                } else {
                    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8).delay(Double(index) * 0.1)) {
                        showBar = true
                    }
                }
            }
        }
    }
}

struct AnimatedHorizontalBarGraph: View {
    @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated: Bool = true
    var category: PowerCategory
    var index: Int

    @State var showBar: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 6)
                .fill(category.category.income ? Color(hex: Color.colorArray[index]) : Color(hex: category.category.wrappedColour))
                .frame(width: showBar ? nil : 0, alignment: .leading)

            Spacer(minLength: 0)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if !animated {
                    showBar = true
                } else {
                    withAnimation(.easeInOut(duration: 0.7).delay(Double(index) * 0.5)) {
                        showBar = true
                    }
                }
            }
        }
    }
}

struct InsightsDollarView: View {
    let amount: Double
    var currencySymbol: String
    var showCents: Bool
    var net: Bool?

    var dollarOffset: CGFloat {
        let bigFont = UIFont.rounded(ofSize: 30, weight: .medium)
        let smallFont = UIFont.rounded(ofSize: 20, weight: .regular)

        return bigFont.capHeight - smallFont.capHeight - 1
    }

    var body: some View {
        if let netPositive = net {
            HStack(alignment: .lastTextBaseline, spacing: 1.3) {
                Text(netPositive ? "+\(currencySymbol)" : "-\(currencySymbol)")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .baselineOffset(dollarOffset)

                if showCents && amount < 100 {
                    Text("\(amount, specifier: "%.2f")")
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                        .lineLimit(1)
                } else {
                    Text("\(amount, specifier: "%.0f")")
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                        .lineLimit(1)
                }
            }
        } else {
            HStack(alignment: .lastTextBaseline, spacing: 1.3) {
                Text(currencySymbol)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .baselineOffset(dollarOffset)

                if showCents && amount < 100 {
                    Text("\(amount, specifier: "%.2f")")
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                        .lineLimit(1)
                } else {
                    Text("\(amount, specifier: "%.0f")")
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                        .lineLimit(1)
                }
            }
        }
    }

    init(amount: Double, currencySymbol: String, showCents: Bool, net: Bool? = nil) {
        self.amount = amount
        self.currencySymbol = currencySymbol
        self.showCents = showCents
        self.net = net
    }
}

func getAverageText(average: Double) -> String {
    let string = String(average)

    let stringArray = string.compactMap { String($0) }

    if average >= 1_000_000 {
        return stringArray[0] + "M"
    } else if average >= 100_000 {
        return string.prefix(3) + "k"
    } else if average >= 10000 {
        return string.prefix(2) + "k"
    } else if average >= 1000 {
        return stringArray[0] + "." + stringArray[1] + "k"
    } else {
        return String(Int(round(average)))
    }
}

let barHeight = 150.0

func getOffset(maxi: Int, average: Double) -> Double {
    if maxi == 0 {
        return 0
    } else {
        let height = (barHeight) - ((average / Double(maxi)) * (barHeight))
        return height - 10
    }
}

func getBarHeight(point: CGFloat, maxi: Int) -> CGFloat {
    if maxi == 0 {
        return 0
    } else {
        let height = (point / CGFloat(maxi)) * barHeight
        return height
    }
}

struct SwipeArrowView: View {
    let left: Bool
    let swipeString: String
    let changeTime: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: left ? "arrow.backward.circle.fill" : "arrow.forward.circle.fill")
                .font(.system(.body, design: .rounded).weight(.medium))
//                                        .font(.system(size: 18, weight: .medium))
                //                                .scaleEffect(changeTime ? 1.3 : 1)
                .foregroundColor(changeTime ? Color.PrimaryText : Color.SecondaryBackground)

            Text(swipeString)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
//                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(changeTime ? Color.PrimaryText : Color.SecondaryBackground)
        }
        .drawingGroup()
    }
}

struct SwipeEndView: View {
    let left: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: left ? "eyeglasses" : "sun.haze.fill")
                .font(.system(.title2, design: .rounded).weight(.medium))
//                                        .font(.system(size: 22, weight: .medium))
                .foregroundColor(Color.SubtitleText)

            Text(left ? "That's all, buddy." : "Into the unknown.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
//                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                .frame(width: 90)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.SubtitleText)
        }
        .opacity(0.8)
        .drawingGroup()
    }
}
