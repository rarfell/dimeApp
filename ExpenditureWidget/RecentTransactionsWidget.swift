//
//  RecentTransactionsWidget.swift
//  ExpenditureWidgetExtension
//
//  Created by Rafael Soh on 12/8/22.
//

import WidgetKit
import SwiftUI


struct RecentExpenditureWidget: Widget {
    let kind: String = "ExpenditureWidget"
    
    private var supportedFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 17, *) {
            return [
                .accessoryRectangular,
                .accessoryInline,
                .systemSmall,
                .systemLarge
            ]
        } else if #available(iOSApplicationExtension 16, *) {
            return [
                .accessoryRectangular,
                .accessoryInline,
                .systemSmall
            ]
        } else {
            return [.systemSmall]
        }
    }

    var body: some WidgetConfiguration {
        
        IntentConfiguration(kind: kind, intent: RecentWidgetConfigurationIntent.self, provider: Provider()) { entry in
            ExpenditureWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Recent Transactions")
        .description("View your latest expenses.")
        .supportedFamilies(supportedFamilies)
    }
}

struct Provider: IntentTimelineProvider {
    typealias Intent = RecentWidgetConfigurationIntent
    
    public typealias Entry = RecentWidgetEntry
    
    func placeholder(in context: Context) -> RecentWidgetEntry {
    
        RecentWidgetEntry(date: Date(), amount: loadAmount(type: .week, insightsType: .net), transactions: loadTransactions(type: .week, count: 9), duration: .week, type: .net)
    }

    func getSnapshot(for configuration: RecentWidgetConfigurationIntent, in context: Context, completion: @escaping (RecentWidgetEntry) -> ()) {
        
        

        let entry = RecentWidgetEntry(date: Date(), amount: loadAmount(type: configuration.duration, insightsType: configuration.insightsType), transactions: loadTransactions(type: configuration.duration, count: 9), duration: configuration.duration, type: configuration.insightsType)
        completion(entry)
    }

    func getTimeline(for configuration: RecentWidgetConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {


        let entry = RecentWidgetEntry(date: Date(), amount: loadAmount(type: configuration.duration, insightsType: configuration.insightsType), transactions: loadTransactions(type: configuration.duration, count: 9), duration: configuration.duration, type: configuration.insightsType)
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        
        completion(timeline)
    }
    
    func loadAmount(type: TimePeriod, insightsType: InsightsType) -> Double {
        let dataController = DataController.shared
        
        let timeframe: Int
        
        switch type {
        case .day:
            timeframe = 1
        case .week:
            timeframe = 2
        case .month:
            timeframe = 3
        case .year:
            timeframe = 4
        default:
            timeframe = 0
        }
        
        switch insightsType {
        case .net:
            let (amount, positive) = dataController.getLogViewTotalNet(type: timeframe)
            
            if positive {
                return amount
            } else {
                return -amount
            }
            
        case .income:
            return dataController.getLogViewTotalIncome(type: timeframe)
        case .expense:
            return dataController.getLogViewTotalSpent(type: timeframe)
        default:
            return 0
        }
    }
    
    func loadTransactions(type: TimePeriod, count: Int) -> [HoldingTransaction] {
        let dataController = DataController.shared
        let itemRequest = dataController.fetchRequestForRecentTransactionsWithCount(type: type, count: count)
        let holding = dataController.results(for: itemRequest)
        
        var sending = [HoldingTransaction]()
        
        holding.forEach { transaction in
            let t = HoldingTransaction(colour: transaction.category?.wrappedColour ?? "", note: transaction.wrappedNote, amount: transaction.wrappedAmount, income: transaction.income)
            
            sending.append(t)
        }
        
        return sending
    }
}

struct RecentWidgetEntry: TimelineEntry {
    let date: Date
    let amount: Double
    let transactions: [HoldingTransaction]
    let duration: TimePeriod
    let type: InsightsType
}

struct HoldingTransaction: Hashable {
    let colour: String
    let note: String
    let amount: Double
    let income: Bool
}

struct ExpenditureWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: Provider.Entry
    
    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }
    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true
        
    var inlineSubtitleText: String {
        switch entry.duration {
        case .unknown:
            return "NIL"
        case .day:
            return String(localized: "today")
        case .week:
            return String(localized: "this week")
        case .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return String(localized: "in \(formatter.string(from: Date.now))")
        case .year:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return String(localized: "in \(formatter.string(from: Date.now))")
        }
    }
    
    var typeText: String {
        switch entry.type {
        case .unknown:
            return ""
        case .net:
            return String(localized: "net")
        case .income:
            return String(localized: "earned")
        case .expense:
            return String(localized: "spent")
        }
    }
    
    var positivityText: String {
        switch entry.type {
        case .unknown:
            return ""
        case .net:
            if entry.amount > 0 {
                return "+"
            } else {
                return "-"
            }
        case .income:
            return "+"
        case .expense:
            return "-"
        }
    }
    
    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            if entry.amount == 0 {
                Text("\(currencySymbol)0 \(typeText) \(inlineSubtitleText)")
            } else {
                Text("\(positivityText)\(currencySymbol)\(abs(entry.amount), specifier: (showCents && entry.amount < 1000) ? "%.2f" : "%.0f") \(inlineSubtitleText)")
            }
        case .accessoryRectangular:
            if #available(iOS 17.0, *) {
                if entry.transactions.count == 0 {
                        Text("NO RECENT EXPENSES")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .containerBackground(for: .widget) { Color.clear }
                } else {
                    GeometryReader { proxy in
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(entry.transactions.prefix(3), id: \.self) { transaction in
                                HStack(spacing: 3) {
                                    Text(transaction.note)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading
                                        )
                                    
                                    Text("\(transaction.income ? "+" : "-")\(currencySymbol)\(transaction.amount, specifier: (showCents && transaction.amount < 100) ? "%.2f" : "%.0f")")
                                        .fontWeight(.regular)
                                        .layoutPriority(1)
                                        .lineLimit(1)
                                       
                                }
                                .font(.system(size: getRectangularWidgetFont(width: proxy.size.width), design: .rounded))
                                
                                
                                
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .containerBackground(for: .widget) { Color.clear }
                }
            } else {
                if entry.transactions.count == 0 {
                        Text("NO RECENT EXPENSES")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                } else {
                    GeometryReader { proxy in
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(entry.transactions.prefix(3), id: \.self) { transaction in
                                HStack(spacing: 3) {
                                    Text(transaction.note)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading
                                        )
                                    
                                    Text("\(transaction.income ? "+" : "-")\(currencySymbol)\(transaction.amount, specifier: (showCents && transaction.amount < 100) ? "%.2f" : "%.0f")")
                                        .fontWeight(.regular)
                                        .layoutPriority(1)
                                        .lineLimit(1)
                                       
                                }
                                .font(.system(size: getRectangularWidgetFont(width: proxy.size.width), design: .rounded))
                                
                                
                                
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                }
            }
        case .systemSmall:
            if #available(iOS 17.0, *) {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            Text((typeText + " " + inlineSubtitleText).uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.SubtitleText)

                            GeometryReader { proxy in
                                RecentTransactionsDollarView(amount: entry.amount, size: proxy.size.width, showCents: showCents, net: entry.type == .net)
                                    .frame(width: proxy.size.width)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: proxy.size.height * 0.27)
                            
                        }
                        .frame(maxWidth: .infinity)
                        
                        
                        if entry.transactions.isEmpty {
                            VStack(spacing: 5) {
                                Text("NO RECENT EXPENSES")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.SubtitleText)
                                    .frame(maxHeight: .infinity)
                                    
                                
                                HStack(spacing: 5) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                    
                                    Text("New Expense")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.PrimaryText)
                                     
                                }
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.SecondaryBackground))
                                .frame(maxHeight: .infinity, alignment: .bottom)
                            }
                            .padding(.top, 12)
                            
                            
                            
                        } else {
                            VStack(alignment: .leading, spacing: 5) {
                               
                                Text("RECENT EXPENSES")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.SubtitleText)
                                
                                
                                ForEach(entry.transactions.prefix(3), id: \.self) { transaction in
                                    HStack(spacing: 5) {
                                        Capsule()
                                            .fill(Color(hex: transaction.colour))
                                            .frame(width: 4, height: 12)
                                        
                                        Text(transaction.note)
                                            .lineLimit(1)
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.PrimaryText)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if transaction.income {
                                            Text("+\(currencySymbol)\(transaction.amount, specifier: (showCents && transaction.amount < 100) ? "%.2f" : "%.0f")")
                                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.IncomeGreen)
                                                .lineLimit(1)
                                                .layoutPriority(1)
                                        } else {
                                            Text("-\(currencySymbol)\(transaction.amount, specifier: (showCents && transaction.amount < 100) ? "%.2f" : "%.0f")")
                                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.SubtitleText)
                                                .lineLimit(1)
                                                .layoutPriority(1)
                                        }
                                        
                                        
                                    }
                                    
                                }
                                
                                
                                if entry.transactions.count < 2 {
                                    
                                    HStack(spacing: 5) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                        
                                        Text("New Expense")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.PrimaryText)
                                         
                                    }
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.SecondaryBackground))
                                    .frame(maxHeight: .infinity, alignment: .bottom)
                                    
                                        
                                            
                                }
                            }
                            .padding(.top, entry.transactions.count >= 3 ? 5 : 10)
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                        
                        
                    }
            
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(for: .widget) {
                    Color.PrimaryBackground
                }
                .widgetURL(entry.transactions.count < 2 ? URL(string: "dimeapp://newExpense") : nil)
            } else {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            Text((typeText + " " + inlineSubtitleText).uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.SubtitleText)

                            GeometryReader { proxy in
                                RecentTransactionsDollarView(amount: entry.amount, size: proxy.size.width, showCents: showCents, net: entry.type == .net)
                                    .frame(width: proxy.size.width)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: proxy.size.height * 0.2)
                            
                        }
                        .frame(maxWidth: .infinity)
                        
                        
                        if entry.transactions.isEmpty {
                            VStack(spacing: 5) {
                                Text("NO RECENT EXPENSES")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.SubtitleText)
                                    .frame(maxHeight: .infinity)
                                    
                                
                                HStack(spacing: 5) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                    
                                    Text("New Expense")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.PrimaryText)
                                     
                                }
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.SecondaryBackground))
                                .frame(maxHeight: .infinity, alignment: .bottom)
                            }
                            .padding(.top, 12)
                            
                            
                            
                        } else {
                            VStack(alignment: .leading, spacing: 5) {
                               
                                Text("RECENT EXPENSES")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.SubtitleText)
                                
                                
                                ForEach(entry.transactions.prefix(3), id: \.self) { transaction in
                                    HStack(spacing: 5) {
                                        Capsule()
                                            .fill(Color(transaction.colour))
                                            .frame(width: 4, height: 12)
                                        
                                        Text(transaction.note)
                                            .lineLimit(1)
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(Color.PrimaryText)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if transaction.income {
                                            Text("+\(currencySymbol)\(transaction.amount, specifier: (showCents && transaction.amount < 100) ? "%.2f" : "%.0f")")
                                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.IncomeGreen)
                                                .lineLimit(1)
                                                .layoutPriority(1)
                                        } else {
                                            Text("-\(currencySymbol)\(transaction.amount, specifier: (showCents && transaction.amount < 100) ? "%.2f" : "%.0f")")
                                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.SubtitleText)
                                                .lineLimit(1)
                                                .layoutPriority(1)
                                        }
                                        
                                        
                                    }
                                    
                                }
                                
                                
                                if entry.transactions.count < 2 {
                                    
                                    HStack(spacing: 5) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                        
                                        Text("New Expense")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.PrimaryText)
                                         
                                    }
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.SecondaryBackground))
                                    .frame(maxHeight: .infinity, alignment: .bottom)
                                    
                                        
                                            
                                }
                            }
                            .padding(.top, entry.transactions.count == 3 ? 5 : 10)
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                        
                        
                    }
                    .padding(15)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.PrimaryBackground)
                .widgetURL(entry.transactions.count < 2 ? URL(string: "dimeapp://newExpense") : nil)
            }
            
        case .systemLarge:
            if #available(iOS 17.0, *) {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            Text((typeText + " " + inlineSubtitleText).uppercased())
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.SubtitleText)

                            
                            RecentTransactionsBiggerDollarView(amount: entry.amount, size: proxy.size.width - 30, showCents: showCents, net: entry.type == .net)
                                .frame(maxWidth: .infinity)
                         
                            
                        }
                        .frame(maxWidth: .infinity)
                        
                        
                        if entry.transactions.isEmpty {
                            VStack(spacing: 20) {
                                Text("NO RECENT EXPENSES")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.SubtitleText)
                                    
                                
                                Link(destination: URL(string: "dimeapp://newExpense")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        
                                        Text("New Expense")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color.PrimaryText)
                                        
                                    }
                                    .padding(.vertical, 6)
                                    .frame(width: 200)
                                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.SecondaryBackground))
                                }
                            }
                            .frame(maxHeight: .infinity)
                            
                            
                            
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                               
                                Text("RECENT EXPENSES")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.SubtitleText)
                                
                                
                                ForEach(entry.transactions, id: \.self) { transaction in
                                    HStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color(hex: transaction.colour))
                                            .frame(width: 15, height: 15)
                                        
                                        Text(transaction.note)
                                            .lineLimit(1)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(Color.PrimaryText)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if transaction.income {
                                            Text("+\(currencySymbol)\(transaction.amount, specifier: (showCents && transaction.amount < 100) ? "%.2f" : "%.0f")")
                                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.IncomeGreen)
                                                .lineLimit(1)
                                                .layoutPriority(1)
                                        } else {
                                            Text("-\(currencySymbol)\(transaction.amount, specifier: (showCents && transaction.amount < 100) ? "%.2f" : "%.0f")")
                                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                                .foregroundColor(Color.SubtitleText)
                                                .lineLimit(1)
                                                .layoutPriority(1)
                                        }
                                        
                                        
                                    }
                                    
                                }
                                
                                
                                if entry.transactions.count < 5 {
                                    Link(destination: URL(string: "dimeapp://newExpense")!) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            
                                            Text("New Expense")
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(Color.PrimaryText)
                                            
                                        }
                                        .padding(.vertical, 6)
                                        .frame(width: 200)
                                        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.SecondaryBackground))
                                    }
                                    .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .bottom)
                                    
                                        
                                            
                                }
                            }
                            .padding(.top, 15)
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                        
                        
                    }
            
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(for: .widget) {
                    Color.PrimaryBackground
                }
            }
            
        
        default:
            EmptyView()
        }
        
        

    }
    
    func getRectangularWidgetFont(width: CGFloat) -> CGFloat {
        var fontSize = 15.0
        
        while fontSize > 12 {
            var max = 0.0
            entry.transactions.forEach { transaction in
                let amountText: String
                if showCents && transaction.amount < 100 {
                    amountText = currencySymbol + String(format: "%.2f", transaction.amount)
                } else {
                    amountText = currencySymbol + String(format: "%.0f", transaction.amount)
                }
                
                let holding = transaction.note.widthOfRoundedString(size: fontSize, weight: .semibold) + amountText.widthOfRoundedString(size: fontSize, weight: .regular) + 8
                
                if holding > max {
                    max = holding
                }
            }
            
            if width > max {
                return fontSize
            }
            
            fontSize -= 1
        }
        
        return 12
    }
    
    
}


struct RecentTransactionsDollarView: View {
    var amount: Double
    var size: CGFloat
    var showCents: Bool
    var net: Bool
    
    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }
    
    var actualAmount: Double {
        if net {
            return abs(amount)
        } else {
            return amount
        }
    }
    
    var downsize: (big: CGFloat, small: CGFloat) {
        let amountText: String
        
        if showCents && amount < 100 {
            amountText = String(format: "%.2f", actualAmount)
        } else {
            amountText = String(format: "%.0f", actualAmount)
        }
        
        if (amountText.widthOfRoundedString(size: 18, weight: .medium) + currencySymbol.widthOfRoundedString(size: 10, weight: .regular) + 1.3) > size {
            return (14, 8)
        } else if (amountText.widthOfRoundedString(size: 24, weight: .medium) + currencySymbol.widthOfRoundedString(size: 15, weight: .regular) + 2) > size {
            return (18, 10)
        } else {
            return (24, 15)
        }
    }
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            if net {
                Text("\(amount < 0 ? "-" : (amount == 0 ? "" : "+"))\(currencySymbol)")
                    .font(.system(size: downsize.small, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .baselineOffset(getDollarOffset(big: downsize.big, small: downsize.small))
            } else {
                Text(currencySymbol)
                    .font(.system(size: downsize.small, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .baselineOffset(getDollarOffset(big: downsize.big, small: downsize.small))
            }
            
            if showCents && actualAmount < 100 {
               Text("\(actualAmount, specifier: "%.2f")")
                    .font(.system(size: downsize.big, weight: .medium, design: .rounded))
                   .foregroundColor(Color.PrimaryText)
                   .lineLimit(1)
           } else {
               Text("\(actualAmount, specifier: "%.0f")")
                   .font(.system(size: downsize.big, weight: .medium, design: .rounded))
                   .foregroundColor(Color.PrimaryText)
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

struct RecentTransactionsBiggerDollarView: View {
    var amount: Double
    var size: CGFloat
    var showCents: Bool
    var net: Bool
    
    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }
    
    var actualAmount: Double {
        if net {
            return abs(amount)
        } else {
            return amount
        }
    }
    
    var downsize: (big: CGFloat, small: CGFloat) {
        let amountText: String
        
        if showCents && amount < 1000 {
            amountText = String(format: "%.2f", actualAmount)
        } else {
            amountText = String(format: "%.0f", actualAmount)
        }
        
        if (amountText.widthOfRoundedString(size: 24, weight: .medium) + currencySymbol.widthOfRoundedString(size: 15, weight: .regular) + 1.3) > size {
            return (18, 12)
        } else if (amountText.widthOfRoundedString(size: 30, weight: .medium) + currencySymbol.widthOfRoundedString(size: 21, weight: .regular) + 2) > size {
            return (24, 15)
        } else {
            return (30, 21)
        }
    }
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            if net {
                Text("\(amount < 0 ? "-" : (amount == 0 ? "" : "+"))\(currencySymbol)")
                    .font(.system(size: downsize.small, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .baselineOffset(getDollarOffset(big: downsize.big, small: downsize.small))
            } else {
                Text(currencySymbol)
                    .font(.system(size: downsize.small, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .baselineOffset(getDollarOffset(big: downsize.big, small: downsize.small))
            }
            
            if showCents && actualAmount < 100 {
               Text("\(actualAmount, specifier: "%.2f")")
                    .font(.system(size: downsize.big, weight: .medium, design: .rounded))
                   .foregroundColor(Color.PrimaryText)
                   .lineLimit(1)
           } else {
               Text("\(actualAmount, specifier: "%.0f")")
                   .font(.system(size: downsize.big, weight: .medium, design: .rounded))
                   .foregroundColor(Color.PrimaryText)
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
