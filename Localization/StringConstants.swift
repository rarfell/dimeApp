//
//  StringConstants.swift
//  dime
//
//  Created by Thiago Lütz Dias on 09/12/23.
//

import SwiftUI

enum LocalizedString: String {
    case new = "new"
    case cancel = "cancel"
    case delete = "delete"
    
    //MARK: - Welcome Sheet
    
    case appName = "app_name"
    case getStarted = "get_started"
    
    // Headers
    case trackFinance = "track_finance"
    case analyzeExpenditure = "analyze_expenditure"
    case stickToBudget = "stick_to_budget"
    
    // Subtitles
    case easilyAddEntries = "easily_add_entries"
    case spendingInsights = "spending_insights"
    case spendingLimitGoals = "spending_limit_goals"
    
    //MARK: - Update Sheet
    
    // Headers
    case siriShortcuts = "siri_shortcuts"
    case dataImport = "data_import"
    case futureTransactions = "future_transactions"
    case appIcons = "app_icons"
    case redesignedScreens = "redesigned_screens"
    case customCategoryColors = "custom_category_colors"
    case newToasts = "new_toasts"
    case customTimeFrames = "custom_time_frames"
    
    // Subtitles
    case siriShortcutsSubtitle = "siri_shortcuts_subttitle"
    case dataImportSubtitle = "data_import_subtitle"
    case futureTransactionsSubtitle = "future_transactions_subtitle"
    case appIconsSubtitle = "app_icons_subtitle"
    case redesignedScreensSubtitle = "redesigned_screens_subtitle"
    case customCategoryColorsSubtitle = "custom_category_colors_subtitle"
    case newToastsSubtitle = "new_toasts_subtitle"
    case customTimeFramesSubtitle = "custom_time_frames_subtitle"
    
    //MARK: - Categories
    case categories = "categories"
    case categoryName = "category_name"

    case income = "income"
    case incomeCategory = "income_category"
    case incomeCategories = "income_categories"
    case noIncomeCategories = "no_income_categories"

    case expense = "expense"
    case expenseCategory = "expense_category"
    case expenseCategories = "expense_categories"
    case noExpenseCategories = "no_expense_categories"

    case suggested = "suggested"
    case suggestionsHidden = "suggestions_hidden"

    case deleteConfirmation = "delete_confirmation"
    case deleteTransactionsWarning = "delete_transactions_warning"
    case actionCannotBeUndoneWarning = "action_cannot_be_undone_warning"

    case editAccordingly = "edit_accordingly"
    case successfullyEdited = "successfully_edited"
    case successfullyAdded = "successfully_added"

    // Validation
    case missingName = "missing_name"
    case missingInformation = "missing_information"
    case missingEmoji = "missing_emoji"
    case incompleteEntry = "incomplete_entry"
    case duplicateFound = "duplicate_found"
    case changeEmoji = "change_emoji"
    case changeName = "change_name"

    // Default categories
    case food = "food"
    case transport = "transport"
    case rent = "rent"
    case subscriptions = "subscriptions"
    case groceries = "groceries"
    case family = "family"
    case utilities = "utilities"
    case fashion = "fashion"
    case healthcare = "healthcare"
    case pets = "pets"
    case sneakers = "sneakers"
    case gifts = "gifts"
    case paycheck = "paycheck"
    case allowance = "allowance"
    case partTime = "part_time"
    case investments = "investments"
    case tips = "tips"
    
    //MARK: - Log View
    case deleteRecurringTransaction = "delete_recurring_transaction"
}

extension String {
    init(_ localizedStringsEnum: LocalizedString, for arguments: CVarArg?...) {
        // Provide default values for nil arguments
        let nonNilArguments = arguments.compactMap { $0 }
        
        // Return a localized string for the enum case
        self = String(format: NSLocalizedString(localizedStringsEnum.rawValue, comment: ""), arguments: nonNilArguments)
    }
}

extension Text {
    init(_ localizedStringsEnum: LocalizedString, for arguments: CVarArg?...) {
        // Provide default values for nil arguments
        let nonNilArguments = arguments.compactMap { $0 }
        
        // Generate a localized string for the enum case
        let localizedString = String(format: NSLocalizedString(localizedStringsEnum.rawValue, comment: ""), arguments: nonNilArguments)

        // Initialize the Text view with the localized string
        self.init(verbatim: localizedString)
    }
}
