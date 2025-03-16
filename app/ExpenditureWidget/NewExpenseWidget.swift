//
//  NewExpenseWidget.swift
//  ExpenditureWidgetExtension
//
//  Created by Rafael Soh on 9/9/22.
//

import SwiftUI
import WidgetKit

struct NewExpenseWidget: Widget {
    let kind: String = "AddExpense"

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 16, *) {
            return [
                .accessoryCircular
            ]
        } else {
            return [WidgetFamily]()
        }
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NewExpenseProvider()) { entry in
            NewExpenseWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("New Expense")
        .description("A convenient button to log new purchases.")
        .supportedFamilies(supportedFamilies)
    }
}

struct NewExpenseProvider: TimelineProvider {
    typealias Entry = NewExpenseWidgetEntry

    func placeholder(in _: Context) -> NewExpenseWidgetEntry {
        NewExpenseWidgetEntry(date: Date())
    }

    func getSnapshot(in _: Context, completion: @escaping (NewExpenseWidgetEntry) -> Void) {
        let entry = NewExpenseWidgetEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<NewExpenseWidgetEntry>) -> Void) {
        let entry = NewExpenseWidgetEntry(date: Date())

        let timeline = Timeline(entries: [entry], policy: .atEnd)

        completion(timeline)
    }
}

struct NewExpenseWidgetEntry: TimelineEntry {
    let date: Date
}

struct NewExpenseWidgetEntryView: View {
    let entry: NewExpenseProvider.Entry

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            ZStack {
                AccessoryWidgetBackground()

                Text("\(currencySymbol.count < 3 ? "+" : "")\(currencySymbol)")
                    .font(.system(size: currencySymbol.count < 3 ? 13 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.SecondaryBackground)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(.horizontal, 9)
            }
            .widgetURL(URL(string: "dimeapp://newExpense"))
            .containerBackground(for: .widget) {
                AccessoryWidgetBackground()
            }
        } else {
            ZStack {
                Circle()
                    .fill(Color.SecondaryBackground.opacity(0.5))

                Text("\(currencySymbol.count < 3 ? "+" : "")\(currencySymbol)")
                    .font(.system(size: currencySymbol.count < 3 ? 13 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.SecondaryBackground)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(.horizontal, 9)
            }
            .padding(0.5)
            .widgetURL(URL(string: "dimeapp://newExpense"))
        }
    }
}
