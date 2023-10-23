//
//  ExpenditureWidget.swift
//  ExpenditureWidget
//
//  Created by Rafael Soh on 25/7/22.
//

import WidgetKit
import SwiftUI


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


