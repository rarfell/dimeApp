//
//  LogView.swift
//  xpenz
//
//  Created by Rafael Soh on 19/5/22.
//

import CloudKitSyncMonitor
import CoreData
import Foundation
import SwiftUIIntrospect
import Popovers
import SwiftUI

struct LogView: View {
    @ObservedObject var syncMonitor = SyncMonitor.shared

    @State var updatedRecurring = false

    @FetchRequest(sortDescriptors: []) private var transactions: FetchedResults<Transaction>

    @EnvironmentObject var dataController: DataController
    @Environment(\.managedObjectContext) var moc

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    var topEdge: CGFloat

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @State var addTransaction = false

    // searching
    @State var searchMode = false

    // top bar
    @State var navBarText = ""
    @State var showMenu = false
    @AppStorage("logTimeFrame", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var logTimeFrame = 2
    let subtitleText = ["today", "this week", "this month", "this year"]

    // show filter menu
    @State var showFilter = false
    @State var filter = FilterType.all

    // filters
    @State var categoryFilter: Category?
    @State var dateFilter = Date.now
    @State var weekFilter = Date.now
    @State var monthFilter = Date.now
    @State var income = false

    // to show/hide tab bar
    var bottomEdge: CGFloat
    var launchSearch: Bool

    // drag to open
//    enum PullToReach {
//        case none, search, filter
//    }

//    @State var pullStatus: PullToReach = .none
//    @State var released: PullToReach = .none

    @State var progress = 0.0

    var body: some View {
        if transactions.isEmpty {
            VStack(spacing: 5) {
                Image("dropbox")
                    .resizable()
                    .frame(width: 75, height: 75)
                    .padding(.bottom, 20)
                    .accessibility(hidden: true)

                Text("Your Log is Empty")
                    .font(.system(.title2, design: .rounded).weight(.medium))
//                    .font(.system(size: 23.5, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.PrimaryText.opacity(0.8))

                Text("Press the plus button\nto add your first entry")
                    .font(.system(.body, design: .rounded).weight(.medium))
//                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.SubtitleText.opacity(0.7))
            }
            .padding(.horizontal, 30)
            .frame(height: 250, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.PrimaryBackground)

        } else {
            VStack(spacing: 0) {
                VStack(spacing: 18) {
                    HStack {
                        Button {
                            searchMode = true
                        } label: {
                            Image(systemName: "magnifyingglass")
//                                .font(.system(size: 23, weight: .regular))
                                .font(.system(.title2, design: .rounded).weight(.regular))
                                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                                .foregroundColor(Color.DarkIcon)
                                .padding(5)
                                .contentShape(Rectangle())
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.SecondaryBackground)
                                        .scaleEffect(progress == 1 ? 1.5 : 1.0)
                                        .opacity(progress)
                                }
                        }
                        .accessibilityLabel("Search")

                        Spacer()

                        switch filter {
                        case .all:
//                            Text(navBarText)
//                            .font(.system(size: 16, weight: .semibold, design: .rounded))
//                            .opacity(0)
                            EmptyView()
                        case .category:
                            filterTagView(text: "filter-tag-category")
                        case .day:
                            filterTagView(text: "filter-tag-day")
                        case .week:
                            filterTagView(text: "filter-tag-week")
                        case .month:
                            filterTagView(text: "filter-tag-month")
                        case .recurring:
                            filterTagView(text: "filter-tag-recurring")
                        case .type:
                            filterTagView(text: "filter-tag-type")
                        case .upcoming:
                            filterTagView(text: "filter-tag-upcoming")
                        }

                        Spacer()

                        Button {
                            showFilter = true
                        } label: {
                            Image(systemName: filter == .all ? "triangle" : "triangle.tophalf.filled")
                                .font(.system(.title2, design: .rounded).weight(.regular))
                                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                                .foregroundColor(Color.DarkIcon)
                                .rotationEffect(Angle(degrees: 180))
                                .padding(5)
                                .contentShape(Rectangle())
                                .background {
                                    if showFilter {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color.SecondaryBackground)
                                    }
//                                    if pullStatus == .filter || showFilter {
//                                        RoundedRectangle(cornerRadius: 7)
//                                            .fill(Color.SecondaryBackground)
//                                            .scaleEffect(released == .filter ? 1.2 : 1.0)
//                                            .opacity(released  == .filter ? 0.5 : 1.0)
//                                    }
                                }
                        }
                        .accessibilityLabel("Filter")
                        .popover(present: $showFilter, attributes: {
                            $0.position = .absolute(
                                originAnchor: .bottomRight,
                                popoverAnchor: .topRight
                            )
                            $0.rubberBandingMode = .none
                            $0.sourceFrameInset = UIEdgeInsets(top: 0, left: 0, bottom: -10, right: 0)
                            $0.presentation.animation = .easeInOut(duration: 0.2)
                            $0.dismissal.animation = .easeInOut(duration: 0.3)
                        }) {
                            FilterPickerView(filterType: $filter, showMenu: $showFilter)
                        }
                    }

                    switch filter {
                    case .all:
                        EmptyView()
                    case .category:
                        CategoryStepperView(categoryFilter: $categoryFilter)
                    case .day:
                        DateStepperView(date: $dateFilter)
                    case .week:
                        WeekStepperView(showingDate: $weekFilter)
                    case .month:
                        MonthStepperView(showingDate: $monthFilter)
                    case .recurring:
                        EmptyView()
                    case .type:
                        IncomeFilterToggleView(income: $income)
                    case .upcoming:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 25)
                .frame(height: (filter == .all || filter == .recurring || filter == .upcoming) ? 50 : 110, alignment: .top)
                .padding(.top, topEdge + 10)

                ScrollView(showsIndicators: false) {
                    if filter == .all {
                        LogInsightsView(navBarText: $navBarText, showCents: showCents, currencySymbol: currencySymbol)
                    }

                    TransactionsList(filter: filter, category: categoryFilter, date: dateFilter, week: weekFilter, month: monthFilter, income: income)
                        .zIndex(0)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 70 + bottomEdge)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

//
//                CustomRefreshView {
//                    VStack {
//
//                    }
//
//                } onRefresh: {
//                    searchMode = true
//                }
//

//                ScrollView(showsIndicators: false) {
//                    if filter == .all {
//                        LogInsightsView(navBarText: $navBarText, showCents: showCents, currencySymbol: currencySymbol)
//
//                    }
//
//
//                    TransactionsList(filter: filter, category: categoryFilter, date: dateFilter, week: weekFilter, month: monthFilter, income: income)
//                        .zIndex(0)
//                        .padding(.horizontal, 20)
//                        .padding(.bottom, 70 + bottomEdge)
                ////                        .offsetExtractor(coordinateSpace: "Scroll") { rect in
                ////                            DispatchQueue.main.async {
                ////                                print(rect.minY)
                ////                                pullStatus = rect.minY > 355 ? (rect.minY > 410 ? .filter : .search) : .none
                ////                            }
                ////                        }
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .onReceive(scrollDelegate.gestureEnded) { _ in
//                    if pullStatus == .filter {
//                        showFilter = true
//                        released = .filter
//                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                    } else if pullStatus == .search {
//                        released = .search
//                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                            searchMode = true
//                        }
//
//                    }
//                }
            }
//            .onAppear(perform: scrollDelegate.addGesture)
//            .onDisappear(perform: scrollDelegate.removeGesture)
            .background(Color.PrimaryBackground)
            .fullScreenCover(isPresented: $searchMode) {
                SearchView()
            }
            .onChange(of: syncMonitor.syncStateSummary) { newState in
                if newState == .succeeded && !updatedRecurring {
                    dataController.updateRecurringTransactions()
                    updatedRecurring = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        updatedRecurring = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if syncMonitor.syncStateSummary == .succeeded && !updatedRecurring {
                    dataController.updateRecurringTransactions()
                    updatedRecurring = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        updatedRecurring = false
                    }
                } else if !NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync") {
                    dataController.updateRecurringTransactions()
                }
            }
            .onChange(of: launchSearch) { _ in
                searchMode = true
            }
            .onAppear {
                if !NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync") {
                    dataController.updateRecurringTransactions()
                }
            }
//            .animation(.spring(duration: 0.5), value: released)
//            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: pullStatus)
//            .onChange(of: pullStatus) { newValue in
//                if newValue != .none && released == .none {
//                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//                }
//            }
//            .onChange(of: released) { _ in
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    released = .none
//                }
//            }
            .onOpenURL { url in
                guard url.host == "search" else {
                    return
                }
                searchMode = true
            }
        }
    }

    @ViewBuilder
    func filterTagView(text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Text(text)
                .font(.system(.body, design: .rounded).weight(.medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            Button {
                withAnimation(.easeIn(duration: 0.15)) {
                    filter = .all
                }
            } label: {
                Image(systemName: "xmark")
//                    .resizable()
//                    .frame(width: 11, height: 11)
                    .font(.system(.caption, design: .rounded).weight(.regular))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .foregroundColor(Color.PrimaryText.opacity(0.7))
            }
            .accessibilityLabel("remove filter")
        }
        .padding(4)
        .padding(.horizontal, 6)
        .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
//        .font(.system(size: 17, weight: .medium, design: .rounded))
        .foregroundColor(Color.PrimaryText)
    }
}

struct NumberView: AnimatableModifier {
    var number: Double
    var dynamicTypeSize: DynamicTypeSize
    let netTotal: Bool
    let positive: Bool

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var fontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall:
            return 46
        case .small:
            return 47
        case .medium:
            return 48
        case .large:
            return 50
        case .xLarge:
            return 56
        case .xxLarge:
            return 58
        case .xxxLarge:
            return 62
        default:
            return 50
        }
    }
    var animatableData: Double {
        get { number }
        set { number = newValue }
    }

    func body(content _: Content) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Group {
                Text(netTotal ? (positive ? "+\(currencySymbol)" : "-\(currencySymbol)") : currencySymbol)
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(Color.SubtitleText) +

                Text("\(number, specifier: showCents  ? "%.2f" : "%.0f")")
                    .font(.system(size: fontSize, weight: .regular, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
            }
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)

    }
}

struct LogInsightsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @Binding var navBarText: String

    let showCents: Bool
    let currencySymbol: String

    @State var showMenu1 = false
    let subtitleText = ["today", "this week", "this month", "this year", "all time"]

    @AppStorage("logInsightsTimeFrame", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var timeframe = 2
    @AppStorage("logInsightsType", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var insightsType = 1

    @AppStorage("logViewLineGraph", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var lineGraph: Bool = false

    var netTotal: (value: Double, positive: Bool) {
        dataController.getLogViewTotalNet(type: timeframe)
    }

    var range: Int {
        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")?.integer(forKey: "firstWeekday") ?? 0
        calendar.minimumDaysInFirstWeek = 4

        if timeframe == 3 {
            let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)

            let thisMonth = calendar.date(from: dateComponents) ?? Date.now
            let numberOfDays = calendar.dateComponents([.day], from: thisMonth, to: Date.now)

            return (numberOfDays.day ?? 0) + 1
        } else if timeframe == 4 {
            let dateComponents = calendar.dateComponents([.year], from: Date.now)

            let thisYear = calendar.date(from: dateComponents) ?? Date.now

            let numberOfMonths = calendar.dateComponents([.month], from: thisYear, to: Date.now)

            return (numberOfMonths.month ?? 0) + 1
        } else {
            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date.now)
            let thisWeek = calendar.date(from: dateComponents) ?? Date.now
            let numberOfDays = calendar.dateComponents([.day], from: thisWeek, to: Date.now)

            return (numberOfDays.day ?? 0) + 1
        }
    }

    var totalSpent: Double {
        return dataController.getLogViewTotalSpent(type: timeframe)
    }

    var totalIncome: Double {
        return dataController.getLogViewTotalIncome(type: timeframe)
    }

    var lineGraphData: [LineGraphDataPoint] {
        if insightsType == 1 {
            return dataController.getLineGraphDataNet(type: timeframe)
        } else if insightsType == 2 {
            return dataController.getLineGraphData(income: true, type: timeframe)
        } else {
            return dataController.getLineGraphData(income: false, type: timeframe)
        }
    }

    var lineGraphGreen: Bool {
        if insightsType == 1 {
            return (lineGraphData.first?.amount ?? 0.0) < (lineGraphData.last?.amount ?? 0.0)
        } else if insightsType == 2 {
            return true
        } else {
            return false
        }
    }

    var amount: Double {
        if insightsType == 1 {
            return netTotal.value
        } else if insightsType == 2 {
            return totalIncome
        } else {
            return totalSpent
        }
    }

    var headingText: String {
        if insightsType == 1 {
            return "Net total"
        } else if insightsType == 2 {
            return "Earned"
        } else {
            return "Spent"
        }
    }

    var body: some View {
        VStack(spacing: -3) {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text(LocalizedStringKey(headingText))
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundColor(Color.PrimaryText.opacity(0.9))
                    Button {
                        showMenu1 = true
                    } label: {
                        Text(LocalizedStringKey(subtitleText[timeframe - 1]))
                            .padding(2)
                            .padding(.horizontal, 6)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(Color.PrimaryText.opacity(9))
                            .overlay(Capsule().stroke(Color.Outline, lineWidth: 1.3))
                    }
                    .popover(present: $showMenu1, attributes: {
                        $0.position = .absolute(
                            originAnchor: .bottom,
                            popoverAnchor: .top
                        )
                        $0.rubberBandingMode = .none
                        $0.sourceFrameInset = UIEdgeInsets(top: 0, left: 0, bottom: -10, right: 0)
                        $0.presentation.animation = .easeInOut(duration: 0.2)
                        $0.dismissal.animation = .easeInOut(duration: 0.3)
                    }) {
                        TimePickerView(showMenu: $showMenu1, timeframe: $timeframe)
                    }
                }

                EmptyView()
                    .modifier(NumberView(number: amount, dynamicTypeSize: _dynamicTypeSize.wrappedValue, netTotal: insightsType == 1, positive: netTotal.positive))
            }
            .padding(7)
            .contentShape(Rectangle())
            .contextMenu {
                if insightsType != 3 {
                    Button {
                        insightsType = 3
                    } label: {
                        Label("Total Spent", systemImage: "minus")
                    }
                }

                if insightsType != 2 {
                    Button {
                        insightsType = 2
                    } label: {
                        Label("Total Income", systemImage: "plus")
                    }
                }

                if insightsType != 1 {
                    Button {
                        insightsType = 1
                    } label: {
                        Label("Net Total", systemImage: "alternatingcurrent")
                    }
                }
            }

            if totalSpent != 0 && totalIncome != 0 && insightsType == 1 {
                HStack {
//                    if showCents {
//                        Text("+\(totalIncome, specifier: "%.2f")")
//                            .font(.system(size: 18, weight: .medium, design: .rounded))
//                            .foregroundColor(Color.IncomeGreen)
//                            .lineLimit(1)
//                    } else {
//                        Text("+\(Int(floor(totalIncome)))")
//                            .font(.system(size: 18, weight: .medium, design: .rounded))
//                            .foregroundColor(Color.IncomeGreen)
//                            .lineLimit(1)
//                    }

                    Text("+\(formatNumber(showCents: showCents, number: totalIncome))")
                        .font(.system(.title2, design: .rounded).weight(.medium))
                        .minimumScaleFactor(0.5)
//                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(Color.IncomeGreen)
                        .lineLimit(1)

                    DottedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
                        .frame(width: 1.7, height: 15)
                        .foregroundColor(Color.Outline)

                    Text("-\(formatNumber(showCents: showCents, number: totalSpent))")
                        .font(.system(.title2, design: .rounded).weight(.medium))
                        .minimumScaleFactor(0.5)
//                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(Color.AlertRed)
                        .lineLimit(1)

//                    if showCents {
//                        Text("-\(totalSpent, specifier: "%.2f")")
//                            .font(.system(size: 18, weight: .medium, design: .rounded))
//                            .foregroundColor(Color.AlertRed)
//                            .lineLimit(1)
//                    } else {
//                        Text("-\(Int(floor(totalSpent)))")
//                            .font(.system(size: 18, weight: .medium, design: .rounded))
//                            .foregroundColor(Color.AlertRed)
//                            .lineLimit(1)
//                    }
                }
                .padding(.bottom, 13)
            }

            if lineGraph {
                LineGraph(data: lineGraphData, green: lineGraphGreen, type: timeframe, range: range)
                    .frame(height: 25)
                    .padding(.horizontal, 60)
                    .padding(.top, 16)
            }
        }
        .padding([.bottom, .horizontal], 20)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(height: lineGraph ? 240 : 170)
    }

    func formatNumber(showCents: Bool, number: Double) -> String {
        if showCents {
            return String(format: "%.2f", number)
        } else {
            return String(format: "%d", Int(floor(number)))
        }
    }
}

struct SearchView: View {
    @Environment(\.dismiss) var dismiss

    @State var searchQuery = ""

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 9) {
                HStack {
                    Image(systemName: "magnifyingglass")
//                        .font(.system(size: 17))
                        .font(.system(.body, design: .rounded).weight(.regular))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundColor(Color.DarkIcon.opacity(0.8))
                        .accessibility(hidden: true)
                    TextField("Search entry by note", text: $searchQuery)
                        .introspect(.textField, on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18)) { textField in
                            textField.becomeFirstResponder()
                        }
                        .font(.system(.body, design: .rounded).weight(.regular))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(Color.PrimaryText)

                    if searchQuery != "" {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(.subheadline, design: .rounded).weight(.regular))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 15))
                                .foregroundColor(Color.SubtitleText)
                                .background(Color.SecondaryBackground)
                        }
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 8))

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundColor(Color.PrimaryText)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }
            }
            
            ScrollView {
                if searchQuery == "" {
                    EmptyView()
                } else {
                    FilteredSearchView(searchQuery: searchQuery)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(15)
        .background(Color.PrimaryBackground)
    }
}

struct FilteredSearchView: View {
    @SectionedFetchRequest<Date?, Transaction> private var transactions: SectionedFetchResults<Date?, Transaction>

    var searchQuery: String

    var body: some View {
        VStack {
            if searchQuery != "" && transactions.count == 0 {
                VStack(spacing: 2) {
                    Text("📭️")
                        .font(.system(size: 50))
                        .padding(.bottom, 15)
                    Text("No entries found.")
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                    Text("Try a different search query!")
                        .font(.system(.subheadline, design: .rounded).weight(.regular))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                }
                .frame(alignment: .center)
                .opacity(0.8)
                .padding(.top, 80)
            }

            ListView(transactions: _transactions)
        }
        .frame(maxHeight: .infinity)
    }

    init(searchQuery: String) {
        let beginPredicate = NSPredicate(format: "%K BEGINSWITH[cd] %@", #keyPath(Transaction.note), searchQuery)
        let containPredicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Transaction.note), searchQuery)
        let containPredicate1 = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Transaction.category.name), searchQuery)

        let compound: NSCompoundPredicate

        // allow searching by amount too
        if let amount = Double(searchQuery) {
            let amountPredicate = NSPredicate(format: "amount == %@", NSNumber(value: amount))
            compound = NSCompoundPredicate(orPredicateWithSubpredicates: [beginPredicate, containPredicate, containPredicate1, amountPredicate])
        } else {
            compound = NSCompoundPredicate(orPredicateWithSubpredicates: [beginPredicate, containPredicate, containPredicate1])
        }

        _transactions = SectionedFetchRequest<Date?, Transaction>(sectionIdentifier: \.day, sortDescriptors: [
            SortDescriptor(\.day, order: .reverse),
            SortDescriptor(\.date, order: .reverse)
        ], predicate: compound)

        self.searchQuery = searchQuery
    }
}

struct TimePickerView: View {
    @Namespace var animation

    let timeframes = ["today", "this week", "this month", "this year", "all time"]

    @Binding var showMenu: Bool
    @Binding var timeframe: Int
    @State var holdingTimeframe = 0

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var colourScheme: Int = 0

    @Environment(\.colorScheme) var systemColorScheme

    var darkMode: Bool {
        (colourScheme == 0 && systemColorScheme == .dark) || colourScheme == 2
    }

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(timeframes.indices, id: \.self) { index in
                HStack {
                    Text(LocalizedStringKey(timeframes[index]))
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)

                    Spacer()

                    if holdingTimeframe == index + 1 {
                        Image(systemName: "checkmark")
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
//                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
//                .font(.system(size: 18, weight: .medium, design: .rounded))
                .padding(5)
                .background {
                    if holdingTimeframe == index + 1 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(darkMode ? Color("AlwaysDarkSecondaryBackground") : Color("AlwaysLightSecondaryBackground"))
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if holdingTimeframe == index + 1 {
                        showMenu = false
                    } else {
                        withAnimation(.easeIn(duration: 0.15)) {
                            holdingTimeframe = index + 1
                        }

                        timeframe = index + 1

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showMenu = false
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
            }
        }
        .foregroundColor(darkMode ? Color("AlwaysLightBackground") : Color("AlwaysDarkBackground"))
        .padding(4)
        .frame(width: dynamicTypeSize > .xxLarge ? 185 : 160)
        .background(RoundedRectangle(cornerRadius: 9).fill(darkMode ? Color("AlwaysDarkBackground") : Color("AlwaysLightBackground")).shadow(color: darkMode ? Color.clear : Color.gray.opacity(0.25), radius: 6))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(darkMode ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
        .onAppear {
            holdingTimeframe = timeframe
        }
    }
}

struct FilterPickerView: View {
    @Namespace var animation
    @Namespace var animation1
    @Binding var filterType: FilterType
    @Binding var showMenu: Bool

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var colourScheme: Int = 0

    @Environment(\.colorScheme) var systemColorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var darkMode: Bool {
        (colourScheme == 0 && systemColorScheme == .dark) || colourScheme == 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(FilterType.allCases, id: \.self) { filter in
                HStack {
                    Image(systemName: FilterType.imageDictionary[filter] ?? "")
//                        .font(.system(size: 16))
                        .font(.system(.callout, design: .rounded).weight(.regular))
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        .frame(width: 20)
                    Text(LocalizedStringKey(filter.rawValue))
//                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        .lineLimit(1)
                    Spacer()

                    if filterType == filter {
                        Image(systemName: "checkmark")
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
//                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(5)
                .background {
                    if filterType == filter {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(darkMode ? Color("AlwaysDarkSecondaryBackground") : Color("AlwaysLightSecondaryBackground"))
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if filterType == filter {
                        showMenu = false
                    } else {
                        withAnimation(.easeIn(duration: 0.15)) {
                            filterType = filter
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showMenu = false
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
            }
        }
        .foregroundColor(darkMode ? Color("AlwaysLightBackground") : Color("AlwaysDarkBackground"))
        .padding(4)
        .frame(width: dynamicTypeSize > .xLarge ? 220 : 190)
        .background(RoundedRectangle(cornerRadius: 9).fill(darkMode ? Color("AlwaysDarkBackground") : Color("AlwaysLightBackground")).shadow(color: darkMode ? Color.clear : Color.gray.opacity(0.25), radius: 6))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(darkMode ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
    }
}

struct TransactionsList: View {
    var filter: FilterType
    var category: Category?
    var date: Date
    var week: Date
    var month: Date
    var income: Bool

    @AppStorage("showUpcomingTransactions", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showUpcoming: Bool = true
    @AppStorage("showUpcomingTransactionsWhenUpcoming", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showSoon: Bool = false

    @EnvironmentObject var dataController: DataController

    @SectionedFetchRequest<Date?, Transaction>(sectionIdentifier: \.day, sortDescriptors: [
        SortDescriptor(\.day, order: .reverse),
        SortDescriptor(\.date, order: .reverse),
        SortDescriptor(\.note)
    ], predicate: NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)) private var transactions: SectionedFetchResults<Date?, Transaction>

    var body: some View {
        VStack {
            if (filter == .all && showUpcoming) || filter == .upcoming {
                FutureListView(dataController: dataController, filterMode: filter == .upcoming, limitedMode: showSoon)
                    .padding(.top, 10)
            }

            switch filter {
            case .all:
                ListView(transactions: _transactions)
            case .category:
                FilteredCategoryView(category: category)
            case .day:
                FilteredDateView(date: date)
            case .week:
                FilteredInsightsView(startDate: week, type: 1)
            case .month:
                FilteredInsightsView(startDate: month, type: 2)
            case .recurring:
                FilteredRecurringView()
            case .type:
                FilteredTypeView(income: income)
            case .upcoming:
                EmptyView()
            }
        }
    }
}

struct ListView: View {
    @SectionedFetchRequest<Date?, Transaction> var transactions: SectionedFetchResults<Date?, Transaction>

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }
    
    @AppStorage("showExpenseOrIncomeSign", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
    var showExpenseOrIncomeSign: Bool = true

    @AppStorage("swapTimeLabel", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var swapTimeLabel: Bool = false

    @EnvironmentObject var toastPresenter: OverallToastPresenter

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(transactions) { day in
                let filtered = filterOutDupes(day: day)
                let dateText = dateConverter(date: day.id ?? Date.now).uppercased()

                VStack(spacing: 0) {
                    VStack(spacing: 4) {
                        HStack {
                            Text(dateText)
                            Spacer()

                            Text(filtered.string)
                                .layoutPriority(1)
                        }
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(currencySymbol)\(String(format: "%.2f", filtered.string)) was spent \(dateConverterAccessibilityLabel(date: day.id ?? Date.now))")

                        Line()
                            .stroke(Color.Outline, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)

                    ForEach(filtered.transactions, id: \.id) { transaction in
                        SingleTransactionView(transaction: transaction, showCents: showCents, currencySymbol: currencySymbol, currency: currency, swapTimeLabel: swapTimeLabel, future: false, showExpenseOrIncomeSign: showExpenseOrIncomeSign)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 10))
                .contextMenu {
                    if #available(iOS 16.0, *) {
                        Button {
                            guard let image = ImageRenderer(content: SingleDayPhotoView(amountText: filtered.string, dateText: dateText, transactions: filtered.transactions, showCents: showCents, currencySymbol: currencySymbol, currency: currency, swapTimeLabel: swapTimeLabel, future: false)).uiImage else {
                                return
                            }

                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

                            self.toastPresenter.showToast.toggle()
                        } label: {
                            Label("Save as Photo", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .padding(.bottom, 18)
            }
        }
    }

    func filterOutDupes(day: SectionedFetchResults<Date?, Transaction>.Element) -> (transactions: [Transaction], string: String) {
        var seen = [Transaction]()
        let filtered = day.filter { entity -> Bool in
            if seen.contains(where: { $0.id == entity.id }) {
                return false
            } else {
                seen.append(entity)
                return true
            }
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = currency

        if showCents {
            numberFormatter.maximumFractionDigits = 2
        } else {
            numberFormatter.maximumFractionDigits = 0
        }

        let total = dayTotal(dayTransaction: filtered)

        let text: String

        if total >= 0 {
            text = "+" + (numberFormatter.string(from: NSNumber(value: total)) ?? "$0")
        } else {
            text = (numberFormatter.string(from: NSNumber(value: total)) ?? "$0")
        }

        return (filtered, text)
    }
}

struct FutureListView: View {
    @EnvironmentObject var dataController: DataController

    @FetchRequest private var fetchedResults: FetchedResults<Transaction>
    var filterMode: Bool
    var limitedMode: Bool

    var transactions: [Transaction] {
        if limitedMode {
            let calendar = Calendar.current

            let startOfToday = calendar.startOfDay(for: Date.now)
            let twoWeeksFromStartOfToday = calendar.date(byAdding: .weekOfYear, value: 2, to: startOfToday)!

            let holding = fetchedResults.filter {
                let date = $0.wrappedDate > Date.now ? $0.wrappedDate : $0.nextTransactionDate

                return date < twoWeeksFromStartOfToday
            }

            return holding.sorted { itemA, itemB in
                let date1 = itemA.wrappedDate > Date.now ? itemA.wrappedDate : itemA.nextTransactionDate
                let date2 = itemB.wrappedDate > Date.now ? itemB.wrappedDate : itemB.nextTransactionDate

                return date1 > date2
            }

        } else {
            return fetchedResults.sorted { itemA, itemB in
                let date1 = itemA.wrappedDate > Date.now ? itemA.wrappedDate : itemA.nextTransactionDate
                let date2 = itemB.wrappedDate > Date.now ? itemB.wrappedDate : itemB.nextTransactionDate

                return date1 > date2
            }
        }
    }

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }
    
    @AppStorage("showExpenseOrIncomeSign", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
    var showExpenseOrIncomeSign: Bool = true

    @AppStorage("swapTimeLabel", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var swapTimeLabel: Bool = false

    var totalString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = currency

        if showCents {
            numberFormatter.maximumFractionDigits = 2
        } else {
            numberFormatter.maximumFractionDigits = 0
        }

        var total = 0.0

        transactions.forEach { transaction in
            if transaction.income {
                total += transaction.amount
            } else {
                total -= transaction.amount
            }
        }

        if total >= 0 {
            return "+" + (numberFormatter.string(from: NSNumber(value: total)) ?? "$0")
        } else {
            return numberFormatter.string(from: NSNumber(value: total)) ?? "$0"
        }
    }

    var body: some View {
        if !transactions.isEmpty {
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack {
                        Text("UPCOMING")
                        Spacer()

                        Text(totalString)
                    }
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .accessibilityElement(children: .ignore)

                    Line()
                        .stroke(Color.Outline, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                }
                .padding(.horizontal, 10)

                ForEach(transactions) { transaction in
                    SingleTransactionView(transaction: transaction, showCents: showCents, currencySymbol: currencySymbol, currency: currency, swapTimeLabel: swapTimeLabel, future: true, showExpenseOrIncomeSign: showExpenseOrIncomeSign)
                }
            }
            .padding(.bottom, 18)
        } else if transactions.isEmpty && filterMode {
            NoResultsView(fullscreen: true)
        } else {
            EmptyView()
        }
    }

    init(dataController _: DataController, filterMode: Bool, limitedMode: Bool) {
        let recurringPredicate = NSPredicate(format: "%K > %i", #keyPath(Transaction.recurringType), 0)
        let futurePredicate = NSPredicate(format: "%K > %@", #keyPath(Transaction.date), Date.now as CVarArg)

        let andPredicate = NSCompoundPredicate(type: .or, subpredicates: [recurringPredicate, futurePredicate])

        _fetchedResults = FetchRequest<Transaction>(sortDescriptors: [], predicate: andPredicate)

        self.filterMode = filterMode
        self.limitedMode = limitedMode
    }
}

struct SingleTransactionView: View {
    let transaction: Transaction
    let showCents: Bool
    let currencySymbol: String
    let currency: String
    let swapTimeLabel: Bool
    let future: Bool
    let showExpenseOrIncomeSign: Bool

    @State var refreshID = UUID()

    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var transactionManager: OverallTransactionManager

    // delete mode
//    @State private var toDelete: Transaction?
//    @State var deleteMode = false
//
//    // edit mode
//    @State private var toEdit: Transaction?

    @State private var offset: CGFloat = 0
    @State private var deleted: Bool = false
    var deletePopup: Bool {
        return abs(offset) > UIScreen.main.bounds.width * 0.2
    }

    var deleteConfirm: Bool {
        return abs(offset) > UIScreen.main.bounds.width * 0.42
    }

    @GestureState var isDragging = false

    var imageSize: Double {
        let scale = min(1.5, 1 + (abs(offset + 40) / 100))
        return scale * 10 as Double
    }

    var imageScale: Double {
        return min(1, 1 + (abs(Double(offset) + 40) / 100))
    }

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
        ZStack(alignment: .trailing) {
            Image(systemName: "xmark")
//                .font(.system(size: 13, weight: .bold))
                .font(.system(.caption, design: .rounded).weight(.bold))
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .foregroundColor(deleteConfirm ? Color.AlertRed : Color.SubtitleText)
                .padding(5)
                .background(deleteConfirm ? Color.AlertRed.opacity(0.23) : Color.SecondaryBackground, in: Circle())
//                .scaleEffect(imageScale)
                .scaleEffect(deleteConfirm ? 1.1 : 1)
                .contentShape(Circle())
                .opacity(deleted ? 0 : 1)
                .padding(.horizontal, 10)
                .offset(x: 80)
                .offset(x: max(-80, offset))

            HStack(spacing: 12) {
                EmojiLogView(emoji: (transaction.category?.wrappedEmoji ?? ""),
                             colour: (transaction.category?.wrappedColour ?? "#FFFFFF"), future: future)
                    .fixedSize(horizontal: true, vertical: true)
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.wrappedNote)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundColor(future ? Color.SubtitleText : Color.PrimaryText)
                        .lineLimit(1)

                    Text(getSubtitle())
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        .foregroundColor(future ? Color.EvenLighterText : Color.SubtitleText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if transaction.income {
                    Text(showExpenseOrIncomeSign ? "+\(transactionAmountString)" : transactionAmountString)
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundColor(future ? Color.SubtitleText : Color.IncomeGreen)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .layoutPriority(1)

                } else {
                    Text(showExpenseOrIncomeSign ? "-\(transactionAmountString)" : transactionAmountString)
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundColor(future ? Color.SubtitleText : Color.PrimaryText)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
            }
            .id(refreshID)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                transactionManager.toEdit = transaction
            }
            .contextMenu {
                if transaction.recurringType > 0 {
                    Button {
                        transaction.recurringType = 0
                        dataController.save()
                    } label: {
                        Label("Stop Recurring", systemImage: "xmark")
                    }
                }

                Button {
                    transactionManager.toEdit = transaction
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                if !(future && transaction.wrappedDate < Date.now && transaction.recurringType > 0) {
                    Button {
                        transactionManager.toDelete = transaction
                        transactionManager.future = future
                        transactionManager.showPopup = true

//                        toDelete = transaction
//                        deleteMode = true
                    } label: {
                        Label("Delete", systemImage: "xmark.bin")
                    }
                }
            }
            .offset(x: offset)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(transaction.wrappedNote), \(currencySymbol)\(String(format: "%.2f", transaction.wrappedAmount)), Transaction Category: \(transaction.category?.wrappedName ?? "Unknown"), Transaction made at \(timeConverterAccessibilityLabel(date: transaction.wrappedDate))")
        }
        .onChange(of: deletePopup) { _ in
            if deletePopup {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .onChange(of: deleteConfirm) { _ in
            if deleteConfirm {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .animation(.easeInOut, value: deletePopup)
        .simultaneousGesture(
            DragGesture()
                .updating($isDragging, body: { _, state, _ in
                    state = true
                })
                .onChanged { value in
                    if value.translation.width < 0 {
                        withAnimation {
                            offset = value.translation.width
                        }
                    }
                }
                .onEnded { _ in
                    if deleteConfirm {
                        deleted = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset -= UIScreen.main.bounds.width
                        }

                        if future, transaction.wrappedDate < Date.now, transaction.recurringType > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    transaction.recurringType = 0
                                    dataController.save()
                                }
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                withAnimation {
                                    moc.delete(transaction)
                                    transactionManager.showToast = true
                                    transactionManager.toDelete = transaction
//                                    transactionManager.future = future
//                                    transactionManager.toDelete = transaction
//                                    transactionManager.deletionType = .instant
                                }
                            }
                        }

                    } else if deletePopup {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = 0
                        }

                        transactionManager.future = future
                        transactionManager.toDelete = transaction
                        transactionManager.showPopup = true
//
//                        toDelete = transaction
//                        deleteMode = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
        .onChange(of: isDragging) { _ in
            if !isDragging && !deleted {
                withAnimation(.easeInOut(duration: 0.3)) {
                    offset = 0
                }
            }
        }
        .onChange(of: transactionManager.toDelete) { newValue in
            if newValue == nil {
                deleted = false
                offset = 0
//                withAnimation(.easeInOut(duration: 0.3)){
//                   offset = 0
//                }
            }
        }
    }

    func getSubtitle() -> String {
        if future {
            if transaction.wrappedDate > Date.now {
                return dateFormatter(date: transaction.wrappedDate)
            } else {
                return dateFormatter(date: transaction.nextTransactionDate)
            }
        } else {
            if swapTimeLabel {
                return transaction.wrappedCategoryName
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"

                return formatter.string(from: transaction.wrappedDate)
            }
        }
    }
}

func dateFormatter(date: Date) -> String {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "d MMM"
    return dateFormatter.string(from: date).uppercased()
}

struct EmojiLogView: View {
    let emoji: String
    let colour: String
    let future: Bool
    let huge: Bool

    var body: some View {
        ZStack {
            if future {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color(hex: colour).opacity(0.73), lineWidth: 2)
                    .foregroundColor(.clear)
            } else {
                RoundedRectangle(cornerRadius: huge ? 20 : 9, style: .continuous)
                    .fill(blend(over: Color(hex: colour), withAlpha: 0.73))
//                RoundedRectangle(cornerRadius: 9, style: .continuous)
//                    .fill(Color.white)
//
//                RoundedRectangle(cornerRadius: 9, style: .continuous)
//                    .fill(Color(hex: colour).opacity(0.73))
            }

            Text(emoji)
                .font(.system(huge ? .title : .title3))
                // future ? .caption :
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                .padding(8)
//                .font(.system(size: huge ? 45 : future ? 16: 20))
        }
        .opacity(future ? 0.6 : 1)
    }

    init(emoji: String, colour: String, future: Bool, huge: Bool = false) {
        self.emoji = emoji
        self.colour = colour
        self.future = future
        self.huge = huge
    }
}

struct DeleteTransactionAlert: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var transactionManager: OverallTransactionManager

    var stopRecurring: Bool {
        if let unwrapped = transactionManager.toDelete {
            return transactionManager.future && unwrapped.wrappedDate < Date.now && unwrapped.recurringType > 0
        } else {
            return false
        }
    }

    @Environment(\.colorScheme) var systemColorScheme

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var bottomEdge: Double = 15

    @State private var offset: CGFloat = 0

    var body: some View {
        if let unwrappedToDelete = transactionManager.toDelete {
            VStack(alignment: .leading, spacing: 1.5) {
                Text(stopRecurring ? "Stop Recurring?" : "Delete '\(unwrappedToDelete.wrappedNote)'?")
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 25, weight: .medium, design: .rounded))
                    .foregroundColor(.PrimaryText)
                    .accessibilityLabel("Delete \(unwrappedToDelete.wrappedNote) transaction confirmation. This action cannot be undone.")

                Text(stopRecurring ? "The transaction will no longer be automatically logged." : "This action cannot be undone.")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.SubtitleText)
                    .padding(.bottom, 25)
                    .accessibility(hidden: true)

                Button {
                    transactionManager.showPopup = false

                    if stopRecurring {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            unwrappedToDelete.recurringType = 0
                            dataController.save()
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            //                            moc.delete(toDelete)
                            moc.delete(unwrappedToDelete)
                            transactionManager.showToast = true
                        }
                    }
                } label: {
                    DeleteButton(text: stopRecurring ? "Confirm" : "Delete", red: true)
                }
                .padding(.bottom, 8)

                Button {
                    transactionManager.showPopup = false
                } label: {
                    DeleteButton(text: "Cancel", red: false)
                }
            }
            .padding(13)
            //            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
//            .offset(y: offset)
//            .gesture(
//                DragGesture()
//                    .onChanged { gesture in
//                        if gesture.translation.height < 0 {
//                            offset = gesture.translation.height / 3
//                        } else {
//                            offset = gesture.translation.height
//                        }
//                    }
//                    .onEnded { value in
//                        if value.translation.height > 20 {
//                            dismiss()
//                        } else {
//                            withAnimation {
//                                offset = 0
//                            }
//
//                        }
//                    }
//            )
            .padding(.horizontal, 17)
            .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
        }
    }
}

struct BackgroundBlurView: UIViewRepresentable {
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}
}

struct FilteredRecurringView: View {
    @SectionedFetchRequest<Date?, Transaction> private var transactions: SectionedFetchResults<Date?, Transaction>

    var body: some View {
        VStack(spacing: 30) {
            if transactions.count == 0 {
                NoResultsView(fullscreen: true)
            }

            ListView(transactions: _transactions)
        }
        .frame(maxHeight: .infinity)
    }

    init() {
        let recurringPredicate = NSPredicate(format: "%K = %d", #keyPath(Transaction.onceRecurring), true)
        let datePredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [recurringPredicate, datePredicate])

        _transactions = SectionedFetchRequest<Date?, Transaction>(sectionIdentifier: \.day, sortDescriptors: [
            SortDescriptor(\.day, order: .reverse),
            SortDescriptor(\.date, order: .reverse),
            SortDescriptor(\.note, order: .reverse)
        ], predicate: andPredicate)
    }
}

struct FilteredTypeView: View {
    @SectionedFetchRequest<Date?, Transaction> private var transactions: SectionedFetchResults<Date?, Transaction>

    var income: Bool

    var body: some View {
        VStack(spacing: 30) {
            if transactions.count == 0 {
                NoResultsView(fullscreen: true)
            }

            ListView(transactions: _transactions)
        }
        .frame(maxHeight: .infinity)
    }

    init(income: Bool) {
        let incomePredicate = NSPredicate(format: "income = %d", income)
        let datePredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [incomePredicate, datePredicate])

        _transactions = SectionedFetchRequest<Date?, Transaction>(sectionIdentifier: \.day, sortDescriptors: [
            SortDescriptor(\.day, order: .reverse),
            SortDescriptor(\.date, order: .reverse)
        ], predicate: andPredicate)

        self.income = income
    }
}

struct FilteredCategoryView: View {
    @SectionedFetchRequest<Date?, Transaction> private var transactions: SectionedFetchResults<Date?, Transaction>

    var category: Category?

    var body: some View {
        VStack(spacing: 30) {
            if transactions.count == 0 || category == nil {
                NoResultsView(fullscreen: true)
            } else {
                ListView(transactions: _transactions)
            }
        }
        .frame(maxHeight: .infinity)
    }

    init(category: Category?) {
        if let unwrappedCategory = category {
            let categoryPredicate = NSPredicate(format: "%K == %@", #keyPath(Transaction.category), unwrappedCategory)
            let datePredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [categoryPredicate, datePredicate])

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

        self.category = category
    }
}

struct FilteredDateView: View {
    @FetchRequest private var transactions: FetchedResults<Transaction>

    var date: Date

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @AppStorage("swapTimeLabel", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var swapTimeLabel: Bool = false

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true
    
    @AppStorage("showExpenseOrIncomeSign", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
    var showExpenseOrIncomeSign: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            if transactions.count == 0 {
                NoResultsView(fullscreen: true)
            }
            ForEach(transactions) { transaction in
                SingleTransactionView(transaction: transaction, showCents: showCents, currencySymbol: currencySymbol, currency: currency, swapTimeLabel: swapTimeLabel, future: false, showExpenseOrIncomeSign: showExpenseOrIncomeSign)
            }
        }
        .frame(maxHeight: .infinity)
    }

    init(date: Date) {
        let datePredicate = NSPredicate(format: "%K == %@", #keyPath(Transaction.day), date as CVarArg)
        let futurePredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [futurePredicate, datePredicate])

        _transactions = FetchRequest<Transaction>(sortDescriptors: [
            SortDescriptor(\.date, order: .reverse)
        ], predicate: andPredicate)

        self.date = date
    }
}

struct NoResultsView: View {
    let fullscreen: Bool

    var body: some View {
        if fullscreen {
            VStack(spacing: 12) {
                Spacer()

                Image(systemName: "tray.full.fill")
                    .font(.system(.largeTitle, design: .rounded))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 38, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)

                Text("No entries found.")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 21, weight: .medium, design: .rounded))
                    .foregroundColor(Color.SubtitleText)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: UIScreen.main.bounds.height * 0.7)
            .opacity(0.7)
        } else {
            VStack(spacing: 12) {
                Spacer()

                //            Text("📭️")
                //                .font(.system(size: 45))
                //                .padding(.bottom, 9)
                //                .accessibility(hidden: true)

                Image(systemName: "tray.full.fill")
                    .font(.system(size: 38, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)

                Text("No entries found.")
                    .font(.system(size: 21, weight: .medium, design: .rounded))
                    .foregroundColor(Color.SubtitleText)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .opacity(0.7)
            .padding(.top, 50)
        }
    }
}

struct CategoryStepperView: View {
    @Binding var categoryFilter: Category?
    @EnvironmentObject var dataController: DataController
    @State var income = false
    @State var categories = [Category]()

    var body: some View {
        HStack(spacing: 8) {
            if income {
                Image(systemName: "plus")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.IncomeGreen)
                    .padding(7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1.0, contentMode: .fit)
//                    .frame(width: 36, height: 36)
                    .background(Color.IncomeGreen.opacity(0.23), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let fetchRequest = dataController.fetchRequestForCategories(income: false)
                        let holding = dataController.results(for: fetchRequest)

                        if holding.isEmpty {
                            return
                        } else {
                            income = false
                            categories = holding
                            categoryFilter = categories[0]
                        }
                    }
            } else {
                Image(systemName: "minus")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.AlertRed)
                    .padding(7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1.0, contentMode: .fit)
//                    .frame(width: 36, height: 36)
                    .background(Color.AlertRed.opacity(0.23), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let fetchRequest = dataController.fetchRequestForCategories(income: true)
                        let holding = dataController.results(for: fetchRequest)

                        if holding.isEmpty {
                            return
                        } else {
                            income = true
                            categories = holding
                            categoryFilter = categories[0]
                        }
                    }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { value in
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { item in
                            HStack(spacing: 5) {
                                Text(item.wrappedEmoji)
                                    .font(.system(.footnote, design: .rounded).weight(.medium))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 13))
                                Text(item.wrappedName)
//                                    .font(.system(size: 17.5, weight: .medium, design: .rounded))
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            }
                            .id(item.id)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .fixedSize(horizontal: false, vertical: true)
//                            .frame(height: 36)
                            .foregroundColor(categoryFilter == item ? Color(hex: item.wrappedColour) : Color.PrimaryText)
                            .background(getBackground(category: item), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                if categoryFilter != item {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.Outline,
                                                      style: StrokeStyle(lineWidth: 1.5))
                                }
                            }
                            .onTapGesture {
                                categoryFilter = item
                                withAnimation {
                                    value.scrollTo(item.id, anchor: .leading)
                                }
                            }
//                            .accessibilityElement(children: .ignore)
//                            .accessibilityLabel("filter \(item.wrappedName) transactions button")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 30)
        .onAppear {
            let fetchRequest = dataController.fetchRequestForCategories(income: income)
            categories = dataController.results(for: fetchRequest)

            if categories.isEmpty {
                categoryFilter = nil
            } else {
                categoryFilter = categories[0]
            }
        }
        .onChange(of: income) { _ in
            if categories.isEmpty {
                categoryFilter = nil
            } else {
                categoryFilter = categories[0]
            }
        }
    }

    func getBackground(category: Category) -> Color {
        if category == categoryFilter {
            return Color(hex: category.wrappedColour).opacity(0.3)
        } else {
            return Color.PrimaryBackground
        }
    }

    init(categoryFilter: Binding<Category?>?) {
        _categoryFilter = categoryFilter ?? Binding.constant(nil)
    }
}

struct IncomeFilterToggleView: View {
    @Binding var income: Bool

    @Namespace var animation

    var body: some View {
        HStack(spacing: 0) {
            Text("Expense")
//                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .font(.system(.body, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundColor(income == false ? Color.PrimaryText : Color.SubtitleText)
                .padding(5.5)
                .padding(.horizontal, 8)
                .background {
                    if income == false {
                        Capsule()
                            .fill(Color.SecondaryBackground)
                            .matchedGeometryEffect(id: "TAB1", in: animation)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    DispatchQueue.main.async {
                        withAnimation(.easeIn(duration: 0.15)) {
                            income = false
                        }
                    }
                }

            Text("filter-picker-income")
//                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .font(.system(.body, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundColor(income == true ? Color.PrimaryText : Color.SubtitleText)
                .padding(5.5)
                .padding(.horizontal, 8)
                .background {
                    if income == true {
                        Capsule()
                            .fill(Color.SecondaryBackground)
                            .matchedGeometryEffect(id: "TAB1", in: animation)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    DispatchQueue.main.async {
                        withAnimation(.easeIn(duration: 0.15)) {
                            income = true
                        }
                    }
                }
        }
        .padding(3)
        .overlay(Capsule().stroke(Color.Outline.opacity(0.4), lineWidth: 1.3))
    }
}

struct DateStepperView: View {
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.day)
    ]) private var transactions: FetchedResults<Transaction>

    @Binding var date: Date
    var endDate: Date {
        if transactions.isEmpty {
            return Date.now
        } else {
            return transactions[0].day ?? Date.now
        }
    }

    let currentDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date.now) ?? Date.now

    var dateString: String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "d MMM yyyy"

        return dateFormatter.string(from: date)
    }

    var body: some View {
        HStack {
            StepperButtonView(left: true, disabled: date <= endDate) {
                if date > endDate {
                    date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? Date.now
                }
            }
            .accessibilityLabel("previous day")

            Spacer()

            Text(dateString)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                .font(.system(size: 20, weight: .bold, design: .rounded))
                .accessibilityLabel("showing transactions on \(dateString)")

            Spacer()

            StepperButtonView(left: false, disabled: date >= currentDate) {
                if date < currentDate {
                    date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? Date.now
                }
            }
            .accessibilityLabel("next day")
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            date = currentDate
        }
    }
}

struct WeekStepperView: View {
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.day)
    ]) private var transactions: FetchedResults<Transaction>

    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.day, order: .reverse)
    ], predicate: NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)) private var transactionsReversed: FetchedResults<Transaction>

    @Binding var showingDate: Date
    var endDate: Date {
        if transactions.isEmpty {
            return Date.now
        } else {
            var calendar = Calendar(identifier: .gregorian)
            calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")?.integer(forKey: "firstWeekday") ?? 0
            calendar.minimumDaysInFirstWeek = 4

            let date = transactions[0].day ?? Date.now

            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: date)

            return calendar.date(from: dateComponents) ?? Date.now
        }
    }

    @State var startDate = Date.now

    var dateString: String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "d MMM"

        let endComponents = DateComponents(day: 7, second: -1)
        let endWeekDate = Calendar.current.date(byAdding: endComponents, to: showingDate) ?? Date.now

        return dateFormatter.string(from: showingDate) + " - " + dateFormatter.string(from: endWeekDate)
    }

    var accessibilityDateString: String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "d MMM"

        let endComponents = DateComponents(day: 7, second: -1)
        let endWeekDate = Calendar.current.date(byAdding: endComponents, to: showingDate) ?? Date.now

        return "showing transactions from " + dateFormatter.string(from: showingDate) + " to " + dateFormatter.string(from: endWeekDate)
    }

    var body: some View {
        HStack {
            StepperButtonView(left: true, disabled: showingDate == endDate) {
                if showingDate > endDate {
                    showingDate = Calendar.current.date(byAdding: .day, value: -7, to: showingDate) ?? Date.now
                }
            }
            .accessibilityLabel("previous week")

            Spacer()

            Text(dateString)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .accessibilityLabel(accessibilityDateString)

            Spacer()

            StepperButtonView(left: false, disabled: showingDate == startDate) {
                if showingDate < startDate {
                    showingDate = Calendar.current.date(byAdding: .day, value: 7, to: showingDate) ?? Date.now
                }
            }
            .accessibilityLabel("next week")
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            var calendar = Calendar(identifier: .gregorian)

            calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")?.integer(forKey: "firstWeekday") ?? 0
            calendar.minimumDaysInFirstWeek = 4

            let date = transactionsReversed[0].day ?? Date.now

            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: date)

            startDate = calendar.date(from: dateComponents) ?? Date.now

            showingDate = startDate
        }
    }
}

struct MonthStepperView: View {
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.day)
    ]) private var transactions: FetchedResults<Transaction>

    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.day, order: .reverse)
    ], predicate: NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)) private var transactionsReversed: FetchedResults<Transaction>

    @Binding var showingDate: Date
    var endDate: Date {
        if transactions.isEmpty {
            return Date.now
        } else {
            let calendar = Calendar(identifier: .gregorian)

            let date = transactions[0].day ?? Date.now

            let dateComponents = calendar.dateComponents([.month, .year], from: date)

            return calendar.date(from: dateComponents) ?? Date.now
        }
    }

    @State var startDate = Date.now

    var dateString: String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "MMM yyyy"

        return dateFormatter.string(from: showingDate)
    }

    var body: some View {
        HStack {
            StepperButtonView(left: true, disabled: showingDate == endDate) {
                if showingDate > endDate {
                    showingDate = Calendar.current.date(byAdding: .month, value: -1, to: showingDate) ?? Date.now
                }
            }
            .accessibilityLabel("previous month")

            Spacer()

            Text(dateString)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .accessibilityLabel("showing transactions in \(dateString)")

            Spacer()

            StepperButtonView(left: false, disabled: showingDate == startDate) {
                if showingDate < startDate {
                    showingDate = Calendar.current.date(byAdding: .month, value: 1, to: showingDate) ?? Date.now
                }
            }
            .accessibilityLabel("next month")
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            let calendar = Calendar(identifier: .gregorian)

            let date = transactionsReversed[0].day ?? Date.now

            let dateComponents = calendar.dateComponents([.month, .year], from: date)

            startDate = calendar.date(from: dateComponents) ?? Date.now

            showingDate = startDate
        }
    }
}

func dateConverter(date: Date) -> String {
    let calendar = Calendar.current

    let dateComponents = calendar.dateComponents([.year], from: Date.now)

    let startOfCurrentYear = calendar.date(from: dateComponents) ?? Date.now

    if calendar.isDateInToday(date) {
        return String(localized: "today")
    } else if calendar.isDateInYesterday(date) {
        return String(localized: "yesterday")
    } else if startOfCurrentYear > date {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "EEE, d MMM yy"

        var string = dateFormatter.string(from: date)
        string.insert("'", at: string.index(string.endIndex, offsetBy: -2))

        return string
    } else {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "EEE, d MMM"

        return dateFormatter.string(from: date)
    }
}

func dateConverterAccessibilityLabel(date: Date) -> String {
    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
        return "today"
    } else if calendar.isDateInYesterday(date) {
        return "yesterday"
    } else {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "EEE, d MMM yyyy"

        return "on " + dateFormatter.string(from: date)
    }
}

func timeConverterAccessibilityLabel(date: Date) -> String {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "h:mm a"

    return dateFormatter.string(from: date)
}

func dayTotal(dayTransaction: [Transaction]) -> Double {
    var total = 0.0

    dayTransaction.forEach { transaction in
        if transaction.income {
            total += transaction.amount
        } else {
            total -= transaction.amount
        }
    }

    return total
}
