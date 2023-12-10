//
//  StringConstants.swift
//  dime
//
//  Created by Thiago Lütz Dias on 09/12/23.
//

import SwiftUI

enum LocalizedString: String {
    case new = "new"
    case edit = "edit"
    case cancel = "cancel"
    case delete = "delete"
    case deleteConfirmation = "delete_confirmation"
    
    
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
    
    
    //MARK: - New Transaction
    case addNote = "add_note"
    case category = "category"
    case currentDate = "today_date"

    // Recurring picker
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case custom = "custom"

    // Custom recurrency picker
    case days = "days"
    case weeks = "weeks"
    case months = "months"
    case customInterval = "custom_interval"
    case repeats = "repeats"

    // Validation
    case missingAmount = "missing_amount"
    case missingCategory = "missing_category"
    
    
    //MARK: - Log View
    
    case deleteRecurringTransaction = "delete_recurring_transaction"
    case logEmpty = "log_empty"
    case firstEntryTip = "add_first_entry_tip"

    case searchByNote = "search_entry_by_note"
    case noEntriesFound = "no_entries_found"
    case tryDifferentQuery = "try_different_query"

    // Search filters
    case allEntries = "all_entries"
    case categoryFilter = "by_category"
    case typeFilter = "by_type"
    case dayFilter = "by_day"
    case weekFilter = "by_week"
    case monthFilter = "by_month"
    case recurringFilter = "recurring"
    case upcomingFilter = "upcoming"

    case totalSpent = "total_spent"
    case totalIncome = "total_income"
    case netTotalCapitalized = "net_total_capitalized"
    case netTotal = "net_total"
    case spent = "spent"
    case earned = "earned"

    case today = "today"
    case yesterday = "yesterday"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case thisYear = "this_year"
    case allTime = "all_time"
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
