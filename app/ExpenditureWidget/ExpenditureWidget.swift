//
//  ExpenditureWidget.swift
//  ExpenditureWidget
//
//  Created by Rafael Soh on 25/7/22.
//

import SwiftUI
import WidgetKit

@main
struct DimeWidgets: WidgetBundle {
    var body: some Widget {
        RecentExpenditureWidget()
        InsightsWidget()
        BudgetWidget()
        LockBudgetWidget()
        MainBudgetWidget()
        NewExpenseWidget()
//        TemplateTransactionWidget()
    }
}
