//
//  TemplateTransactionWidget.swift
//  ExpenditureWidgetExtension
//
//  Created by Rafael Soh on 11/9/23.
//

// import WidgetKit
// import SwiftUI
// import AppIntents
//
// struct TemplateTransactionWidget: Widget {
//    let kind: String = "TemplateTransactions"
//
////    private var supportedFamilies: [WidgetFamily] {
////        if #available(iOSApplicationExtension 16, *) {
////            return [
////                .systemSmall
////            ]
////        } else {
////            return [WidgetFamily]()
////        }
////    }
//
//    var body: some WidgetConfiguration {
//        StaticConfiguration(kind: kind, provider: TemplateTransactionWidgetProvider()) { entry in
//            TemplateTransactionWidgetEntryView(entry: entry)
//        }
//        .supportedFamilies([.systemSmall])
//        .configurationDisplayName("New Expense")
//        .description("A convenient button to log new purchases.")
//    }
// }
//
// struct TemplateTransactionWidgetProvider: TimelineProvider {
//
//    typealias Entry = TemplateTransactionWidgetEntry
//
//    func placeholder(in context: Context) -> TemplateTransactionWidgetEntry {
//        let fetched = loadData()
//        return TemplateTransactionWidgetEntry(date: Date(), added: fetched.added, gridItems: fetched.transactions)
//    }
//
//    func getSnapshot(in context: Context, completion: @escaping (TemplateTransactionWidgetEntry) -> Void) {
//        let fetched = loadData()
//        let entry = TemplateTransactionWidgetEntry(date: Date(), added: fetched.added, gridItems: fetched.transactions)
//        completion(entry)
//    }
//
//    func getTimeline(in context: Context, completion: @escaping (Timeline<TemplateTransactionWidgetEntry>) -> Void) {
//        let fetched = loadData()
//        let entry = TemplateTransactionWidgetEntry(date: Date(), added: fetched.added, gridItems: fetched.transactions)
//
//        let timeline = Timeline(entries: [entry], policy: .atEnd)
//
//        completion(timeline)
//    }
//
//    func loadData() -> (transactions:[HoldingTemplateTransaction], added: Bool) {
//        let dataController = DataController.shared
//        let fetchedTemplates = dataController.getAllTemplateTransactions()
//
//        var holding = [HoldingTemplateTransaction]()
//
//        for i in 0...3 {
//            let match = fetchedTemplates.first(where: {
//                $0.order == i
//            })
//
//            holding.append(HoldingTemplateTransaction(id: i, transaction: match))
//        }
//
//        let addedTransaction = dataController.addedTransaction
//
//        return (holding, addedTransaction)
//    }
// }
//
// struct TemplateTransactionWidgetEntry: TimelineEntry, Hashable {
//    let date: Date
//    let added: Bool
//    let gridItems: [HoldingTemplateTransaction]
// }
//
// struct HoldingTemplateTransaction: Hashable, Identifiable {
//    let id: Int
//    let transaction: TemplateTransaction?
// }
//
//
// struct TemplateTransactionWidgetEntryView: View {
//
//    let entry: TemplateTransactionWidgetProvider.Entry
//
//    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true
//    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
//    var currencySymbol: String {
//        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
//    }
//
//    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
//
//    let individualGridCornerRadius: CGFloat = 10
//
//    var body: some View {
//        if #available(iOS 17.0, *) {
//            if entry.added {
//                VStack(spacing: 7) {
//                    Image(systemName: "checkmark")
//                        .font(.system(size: 16, weight: .semibold, design: .rounded))
//                        .foregroundColor(Color.IncomeGreen)
//                        .frame(width: 30, height: 30)
//                        .background(Color.IncomeGreen.opacity(0.3), in: Circle())
//
//                    Text("Transaction Added")
//                        .font(.system(size: 15, weight: .semibold, design: .rounded))
//                        .foregroundColor(Color.IncomeGreen)
//                        .multilineTextAlignment(.center)
//                }
//                .containerBackground(for: .widget) {
//                    Color.PrimaryBackground
//                }
//                .transition(.push(from: .bottom))
//            } else {
//                GeometryReader { proxy in
//                    let square = (proxy.size.width - 10) / 2
//
//                    LazyVGrid(columns: columns, spacing: 10) {
//                        ForEach(entry.gridItems) { gridItem in
//
//        //                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                if let transaction = gridItem.transaction {
//                                    Button(intent: TemplateTransactionIntent(order: Int(transaction.order))) {
//                                        SingleTemplateWidgetButton(transaction: transaction, showCents: showCents, currencySymbol: currencySymbol, size: square - 10, cornerRadius: individualGridCornerRadius)
//                                            .frame(width: square, height:square)
//                                    }
//                                    .buttonStyle(PlainButtonStyle())
//                                } else {
//                                    RoundedRectangle(cornerRadius: individualGridCornerRadius)
//                                        .fill(Color.SecondaryBackground)
//                                        .frame(width: square, height:square)
//                                }
//
//
//                        }
//                    }
//                    .frame(width: proxy.size.width, height: proxy.size.height)
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .containerBackground(for: .widget) {
//                    Color.PrimaryBackground
//                }
//                .id(entry)
//                .transition(.push(from: .bottom))
//            }
//
//        } else {
//            ZStack {
//                Circle()
//                    .fill(Color.SecondaryBackground.opacity(0.5))
//
//
//                Text("\(currencySymbol.count < 3 ? "+" : "")\(currencySymbol)")
//                    .font(.system(size: currencySymbol.count < 3 ? 13 : 11, weight: .bold, design: .rounded))
//                    .foregroundColor(Color.SecondaryBackground)
//                    .padding(.vertical, 2)
//                    .frame(maxWidth: .infinity)
//                    .background(Color.white, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
//                    .padding(.horizontal, 9)
//
//            }
//            .padding(0.5)
//            .widgetURL(URL(string: "dimeapp://newExpense"))
//        }
//
//    }
// }
//
// struct SingleTemplateWidgetButton: View {
//    let transaction: TemplateTransaction
//    let showCents: Bool
//    let currencySymbol: String
//    let size: CGFloat
//    let cornerRadius: CGFloat
//
//    var downsize: (big: CGFloat, small: CGFloat, amountText: String) {
//        let amountText: String
//
//        if showCents && transaction.amount < 100 {
//            amountText = String(format: "%.2f", transaction.amount)
//        } else {
//            amountText = String(format: "%.0f", transaction.amount)
//        }
//
//        if amountText.widthOfRoundedString(size: 12, weight: .semibold) + currencySymbol.widthOfRoundedString(size: 9, weight: .semibold) > size {
//            return (10, 7.5, amountText)
//        } else if amountText.widthOfRoundedString(size: 15, weight: .semibold) + currencySymbol.widthOfRoundedString(size: 12, weight: .semibold) > size {
//            return (12, 9, amountText)
//        } else {
//            return (15, 12, amountText)
//        }
//    }
//
//
//    var transactionColor: Color {
//        if transaction.category?.income ?? false {
//            return Color.IncomeGreen
//        } else {
//            return Color(hex: transaction.wrappedColour)
//        }
//    }
//
//    var body: some View {
//        VStack(spacing: 6) {
//            Text(transaction.wrappedEmoji)
//                .font(.system(size: 14, weight: .semibold, design: .rounded))
////                .padding(5)
////                .background(blend(over: transactionColor, withAlpha: 0.3), in: RoundedRectangle(cornerRadius: 8))
//
//
//            HStack(alignment: .lastTextBaseline, spacing: 0.5) {
//                Text(currencySymbol)
//                    .font(.system(size: downsize.small, weight: .semibold, design: .rounded))
//                    .foregroundColor(Color.PrimaryText.opacity(0.8))
//                    .baselineOffset(getDollarOffset(big: downsize.big, small: downsize.small))
//
//
//                Text(downsize.amountText)
//                    .font(.system(size: downsize.big, weight: .semibold, design: .rounded))
//                    .foregroundColor(Color.PrimaryText.opacity(0.8))
//
//            }
//            .frame(height: size / 2.5, alignment: .bottom)
//
//        }
//        .padding(5)
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
//        .background(blend(over: transactionColor, withAlpha: 0.8), in: RoundedRectangle(cornerRadius: cornerRadius))
//        .shadow(color: transactionColor.opacity(0.8), radius: 6)
//    }
// }
//
// func getDollarOffset(big: CGFloat, small: CGFloat) -> CGFloat {
//    let bigFont = UIFont.rounded(ofSize: big, weight: .semibold)
//    let smallFont = UIFont.rounded(ofSize: small, weight: .semibold)
//
//    return bigFont.capHeight - smallFont.capHeight
// }

// @available(iOS 16.0, *)
// struct TemplateTransactionIntent: AppIntent {
//    static var title: LocalizedStringResource = "Quick Add Transaction"
//    static var description = IntentDescription("Log a drink and its caffeine amount.")
//
//    @Parameter(title: "Template Transaction Order")
//    var order: Int
//
//    init() {}
//
//    init(order: Int) {
//        self.order = order
//    }
//
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        let dataController = DataController.shared
//
//        dataController.newTemplateTransaction(order: order)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            dataController.addedTransaction = false
//            WidgetCenter.shared.reloadTimelines(ofKind: "TemplateTransactions")
//
//        }
//
//        return .result(dialog: "Hello")
//
//
//    }
// }
