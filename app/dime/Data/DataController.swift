//
//  DataController.swift
//  Bonsai
//
//  Created by Rafael Soh on 3/6/22.
//

import CoreData
import Foundation
import SwiftUI
import WidgetKit

@available(iOS 16, *)
enum CustomError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case notFound,
         coreDataSave,
         unknownId(id: String),
         unknownError(message: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case let .unknownError(message): return "An unknown error occurred: \(message)"
        case let .unknownId(id): return "No category with an ID matching: \(id)"
        case .notFound: return "Category not found"
        case .coreDataSave: return "Couldn't save to CoreData"
        }
    }
}

class DataController: ObservableObject {
    static let shared = DataController()

    var container = NSPersistentCloudKitContainer(name: "MainModel")

    init() {
        let description = NSPersistentStoreDescription()

        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

//        let keyValueStore = NSUbiquitousKeyValueStore.default
//
//        if keyValueStore.object(forKey: "icloud_sync") == nil {
//            keyValueStore.set(true, forKey: "icloud_sync")
//        }
//
//        if !keyValueStore.bool(forKey: "icloud_sync") {
//            description.cloudKitContainerOptions = nil
//        } else {
//            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.rafaelsoh.dime")
//        }

        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.rafaelsoh.dime")

        let groupID = "group.com.rafaelsoh.dime"

        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            description.url = url.appendingPathComponent("Main.sqlite")
        }

        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { description, error in

            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo) for \(description)")
            }

            self.container.viewContext.automaticallyMergesChangesFromParent = true
        }

//        #if DEBUG
//            do {
//                // Use the container to initialize the development schema.
//                try container.initializeCloudKitSchema(options: [])
//            } catch {
//                // Handle any errors.
//            }
//        #endif
////        do {
////            try container.initializeCloudKitSchema()
////        } catch {
////            print(error)
////        }
    }

    // internal variables

    var tipCounter: Int {
        get {
            UserDefaults.standard.integer(forKey: "tipCounter")
        }

        set {
            UserDefaults.standard.set(newValue, forKey: "tipCounter")
        }
    }

    var addedTransaction: Bool {
        get {
            UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.bool(forKey: "newTransactionAdded")
        }

        set {
            UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.set(newValue, forKey: "newTransactionAdded")
        }
    }

    // adding or deleting

    func deleteAll() {
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = Transaction.fetchRequest()
        let batchDeleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        _ = try? container.viewContext.executeAndMergeChanges(using: batchDeleteRequest1)

        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = Category.fetchRequest()
        let batchDeleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        _ = try? container.viewContext.executeAndMergeChanges(using: batchDeleteRequest2)

        let fetchRequest3: NSFetchRequest<NSFetchRequestResult> = Budget.fetchRequest()
        let batchDeleteRequest3 = NSBatchDeleteRequest(fetchRequest: fetchRequest3)
        _ = try? container.viewContext.executeAndMergeChanges(using: batchDeleteRequest3)

        let fetchRequest4: NSFetchRequest<NSFetchRequestResult> = MainBudget.fetchRequest()
        let batchDeleteRequest4 = NSBatchDeleteRequest(fetchRequest: fetchRequest4)
        _ = try? container.viewContext.executeAndMergeChanges(using: batchDeleteRequest4)
    }

    func save() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func updateRecurringTransaction(transaction: Transaction) {
        if transaction.nextTransactionDate < Calendar.current.startOfDay(for: Date.now) {
            var holdingDate = transaction.nextTransactionDate

            while holdingDate <= Calendar.current.startOfDay(for: Date.now) {
                let newTransaction = Transaction(context: container.viewContext)
                newTransaction.note = transaction.wrappedNote
                newTransaction.category = transaction.category
                newTransaction.amount = transaction.wrappedAmount
                newTransaction.date = holdingDate
                newTransaction.id = UUID()
                newTransaction.income = transaction.income
                newTransaction.day = holdingDate

                let calendar = Calendar(identifier: .gregorian)

                let dateComponents = calendar.dateComponents([.month, .year], from: holdingDate)

                newTransaction.month = calendar.date(from: dateComponents)!

                newTransaction.onceRecurring = true

                var newDate: Date?

                if transaction.recurringType == 1 {
                    newDate = Calendar.current.date(byAdding: .day, value: Int(transaction.recurringCoefficient), to: holdingDate)!
                } else if transaction.recurringType == 2 {
                    newDate = Calendar.current.date(byAdding: .day, value: Int(transaction.recurringCoefficient * 7), to: holdingDate)!
                } else if transaction.recurringType == 3 {
                    newDate = Calendar.current.date(byAdding: .month, value: Int(transaction.recurringCoefficient), to: holdingDate)!
                }

                if newDate! > Calendar.current.startOfDay(for: Date.now) {
                    newTransaction.recurringType = transaction.recurringType
                    newTransaction.recurringCoefficient = transaction.recurringCoefficient
                } else {
                    newTransaction.recurringType = 0
                }

                holdingDate = newDate!
            }

            transaction.recurringType = 0

            save()

        } else if Calendar.current.isDateInToday(transaction.nextTransactionDate) {
            let newTransaction = Transaction(context: container.viewContext)
            newTransaction.note = transaction.wrappedNote
            newTransaction.category = transaction.category
            newTransaction.amount = transaction.wrappedAmount
            newTransaction.date = transaction.nextTransactionDate
            newTransaction.id = UUID()
            newTransaction.income = transaction.income
            newTransaction.day = transaction.nextTransactionDate

            let calendar = Calendar(identifier: .gregorian)

            let dateComponents = calendar.dateComponents([.month, .year], from: transaction.nextTransactionDate)

            newTransaction.month = calendar.date(from: dateComponents)!

            newTransaction.onceRecurring = true
            newTransaction.recurringType = transaction.recurringType
            newTransaction.recurringCoefficient = transaction.recurringCoefficient

            transaction.recurringType = 0

            save()
        }
    }

    func updateRecurringTransactions() {
        let recurringTransactions = results(for: fetchRequestForRecurringTransactions())

        recurringTransactions.forEach { transaction in
            updateRecurringTransaction(transaction: transaction)
        }
    }

    func updateBudgetDates() {
        let budgets = results(for: fetchRequestForBudgets())
        let mainBudget = results(for: fetchRequestForMainBudget())

        budgets.forEach { budget in
            while budget.endDate <= Date.now {
                budget.startDate = budget.endDate
            }
        }

        mainBudget.forEach { budget in
            while budget.endDate <= Date.now {
                budget.startDate = budget.endDate
            }
        }

        save()
    }

    func newTransaction(note: String, category: Category?, income: Bool, amount: Double, date: Date, repeatType: Int, repeatCoefficient: Int, delay _: Bool) -> Transaction {
        let transaction = Transaction(context: container.viewContext)

        if note.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            transaction.note = category?.wrappedName ?? ""
        } else {
            transaction.note = note.trimmingCharacters(in: .whitespaces)
        }

        transaction.income = income

        if let unwrappedCategory = category {
            transaction.category = unwrappedCategory
        }

        transaction.amount = amount
        transaction.date = date
        transaction.id = UUID()

        let calendar = Calendar(identifier: .gregorian)

        transaction.day = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) ?? Date.now

        let dateComponents = calendar.dateComponents([.month, .year], from: date)

        transaction.month = calendar.date(from: dateComponents) ?? Date.now

        if repeatType > 0 {
            transaction.onceRecurring = true
            transaction.recurringType = Int16(repeatType)
            transaction.recurringCoefficient = Int16(repeatCoefficient)
            updateRecurringTransaction(transaction: transaction)
        }

        save()

        return transaction
    }

    func newTemplateTransaction(order: Int) {
        if let match = getTemplateTransaction(order: order) {
            if let unwrappedCategory = match.category {
                _ = newTransaction(note: match.note ?? "", category: unwrappedCategory, income: match.income, amount: match.amount, date: Date.now, repeatType: Int(match.recurringType), repeatCoefficient: Int(match.recurringCoefficient), delay: false)

                addedTransaction = true
            }
        }
    }

    // fetching

    func fetchRequestForRecurringTransactions() -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "%K > %i", #keyPath(Transaction.recurringType), 0)
        return itemRequest
    }

    func getTemplateTransaction(order: Int) -> TemplateTransaction? {
        let itemRequest: NSFetchRequest<TemplateTransaction> = TemplateTransaction.fetchRequest()

        itemRequest.predicate = NSPredicate(format: "order == %d", order)

        let results = results(for: itemRequest)

        if results.count > 1 {
            let output = results.first

            for i in 1 ..< results.count {
                container.viewContext.delete(results[i])
            }

            save()

            return output
        } else {
            return results.first
        }
    }

    func getAllTemplateTransactions() -> [TemplateTransaction] {
        let itemRequest: NSFetchRequest<TemplateTransaction> = TemplateTransaction.fetchRequest()

        return results(for: itemRequest)
    }

    func fetchRequestForRecentTransactions(type: TimePeriod) -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        switch type {
        case .unknown:
            return itemRequest
        case .day:
            let today = calendar.startOfDay(for: Date.now)
            let nextDay = calendar.date(byAdding: .day, value: 1, to: today)!

            let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), today as CVarArg)
            let endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), nextDay as CVarArg)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])

            itemRequest.predicate = andPredicate
            itemRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]

            return itemRequest
        case .week:
            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date.now)

            let thisWeek = calendar.date(from: dateComponents)!
            let nextWeek = calendar.date(byAdding: .day, value: 7, to: thisWeek)!

            let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), thisWeek as CVarArg)
            let endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), nextWeek as CVarArg)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])

            itemRequest.predicate = andPredicate
            itemRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]

            return itemRequest
        case .month:
            let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)

            let thisMonth = calendar.date(from: dateComponents)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: thisMonth)!

            let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), thisMonth as CVarArg)
            let endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), nextMonth as CVarArg)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])

            itemRequest.predicate = andPredicate
            itemRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]

            return itemRequest
        case .year:
            let dateComponents = calendar.dateComponents([.year], from: Date.now)

            let thisYear = calendar.date(from: dateComponents)!
            let nextYear = calendar.date(byAdding: .year, value: 1, to: thisYear)!

            let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), thisYear as CVarArg)
            let endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), nextYear as CVarArg)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])

            itemRequest.predicate = andPredicate
            itemRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]

            return itemRequest
        }
    }

    func fetchRequestForExport() -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        itemRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return itemRequest
    }

    func fetchRequestForCategoriesMigration(income: Bool? = nil) -> NSFetchRequest<Category> {
        let itemRequest: NSFetchRequest<Category> = Category.fetchRequest()
        itemRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]

        if let unwrappedIncome = income {
            itemRequest.predicate = NSPredicate(format: "income = %d", unwrappedIncome)
            return itemRequest
        } else {
            return itemRequest
        }
    }

    func fetchRequestForCategories(income: Bool) -> NSFetchRequest<Category> {
        let itemRequest: NSFetchRequest<Category> = Category.fetchRequest()
        itemRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        itemRequest.predicate = NSPredicate(format: "income = %d", income)
        return itemRequest
    }

    func getAllCategories(income: Bool) -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        request.predicate = NSPredicate(format: "income = %d", income)

        return results(for: request)
    }

    func getSuggestedNotes(searchQuery: String, category: Category?, income: Bool) -> [Transaction] {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        itemRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]

        let beginPredicate = NSPredicate(format: "%K BEGINSWITH[cd] %@", #keyPath(Transaction.note), searchQuery)
        let containPredicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Transaction.note), searchQuery)
        let compound = NSCompoundPredicate(orPredicateWithSubpredicates: [beginPredicate, containPredicate])

        let incomePredicate = NSPredicate(format: "income = %d", income)

        if let unwrappedCategory = category {
            let categoryPredicate = NSPredicate(format: "%K == %@", #keyPath(Transaction.category), unwrappedCategory)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [compound, categoryPredicate, incomePredicate])

            itemRequest.predicate = andPredicate
        } else {
            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [compound, incomePredicate])
            itemRequest.predicate = andPredicate
        }

        let transactions = results(for: itemRequest)

        var seen = [Transaction]()
        let filtered = transactions.filter { entity -> Bool in
            if seen.contains(where: { $0.wrappedNote == entity.wrappedNote }) {
                return false
            } else {
                seen.append(entity)
                return true
            }
        }

        return filtered
//
//        let notes = transactions.map { $0.wrappedNote }
//
//        return Array(Set(notes))
    }

    @available(iOS 16, *)
    func findCategory(withId id: UUID) throws -> Category {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id = %@", id as CVarArg)

        do {
            guard let foundCategory = try container.viewContext.fetch(request).first else {
                throw CustomError.notFound
            }
            return foundCategory
        } catch {
            throw CustomError.notFound
        }
    }

    func getAllBudgets() -> [Budget] {
        let request: NSFetchRequest<Budget> = Budget.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]
        return results(for: request)
    }

    @available(iOS 16, *)
    func findBudget(withId id: UUID) throws -> Budget {
        let request: NSFetchRequest<Budget> = Budget.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id = %@", id as CVarArg)

        do {
            guard let foundBudget = try container.viewContext.fetch(request).first else {
                throw CustomError.notFound
            }
            return foundBudget
        } catch {
            throw CustomError.notFound
        }
    }

    func categoryCheck(name: String, emoji: String, income: Bool) -> (error: CategoryError, order: Int64) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines) == "" && emoji == "" {
            return (CategoryError.incomplete, 0)
        } else if name.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return (CategoryError.missingName, 0)
        } else if emoji == "" {
            return (CategoryError.missingEmoji, 0)
        }

        if income {
            let fetchRequest = fetchRequestForCategories(income: true)
            let incomeCategories = results(for: fetchRequest)

            var emojiArray = [String]()
            var nameArray = [String]()

            incomeCategories.forEach { category in
                emojiArray.append(category.wrappedEmoji)
                nameArray.append(category.wrappedName)
            }

            if emojiArray.contains(emoji) && nameArray.contains(name) {
                return (CategoryError.duplicate, 0)
            } else if emojiArray.contains(emoji) {
                return (CategoryError.duplicateEmoji, 0)
            } else if nameArray.contains(name) {
                return (CategoryError.duplicateName, 0)
            } else {
                let newItemOrder = (incomeCategories.last?.order ?? 0) + 1
                return (CategoryError.none, newItemOrder)
            }
        } else {
            let fetchRequest = fetchRequestForCategories(income: false)
            let expenseCategories = results(for: fetchRequest)

            var emojiArray = [String]()
            var nameArray = [String]()

            expenseCategories.forEach { category in
                emojiArray.append(category.wrappedEmoji)
                nameArray.append(category.wrappedName)
            }

            if emojiArray.contains(emoji) && nameArray.contains(name) {
                return (CategoryError.duplicate, 0)
            } else if emojiArray.contains(emoji) {
                return (CategoryError.duplicateEmoji, 0)
            } else if nameArray.contains(name) {
                return (CategoryError.duplicateName, 0)
            } else {
                let newItemOrder = (expenseCategories.last?.order ?? 0) + 1
                return (CategoryError.none, newItemOrder)
            }
        }
    }

    func categoryCheckEdit(name: String, emoji: String, toEdit: Category) -> (error: CategoryError, order: Int64) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines) == "" && emoji == "" {
            return (CategoryError.incomplete, 0)
        } else if name.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return (CategoryError.missingName, 0)
        } else if emoji == "" {
            return (CategoryError.missingEmoji, 0)
        }

        if toEdit.income {
            let fetchRequest = fetchRequestForCategories(income: true)
            var incomeCategories = results(for: fetchRequest)

            if let position = incomeCategories.firstIndex(of: toEdit) {
                incomeCategories.remove(at: position)
            }

            var emojiArray = [String]()
            var nameArray = [String]()

            incomeCategories.forEach { category in
                emojiArray.append(category.wrappedEmoji)
                nameArray.append(category.wrappedName)
            }

            if emojiArray.contains(emoji) && nameArray.contains(name) {
                return (CategoryError.duplicate, 0)
            } else if emojiArray.contains(emoji) {
                return (CategoryError.duplicateEmoji, 0)
            } else if nameArray.contains(name) {
                return (CategoryError.duplicateName, 0)
            } else {
                let newItemOrder = (incomeCategories.last?.order ?? 0) + 1
                return (CategoryError.none, newItemOrder)
            }
        } else {
            let fetchRequest = fetchRequestForCategories(income: false)
            var expenseCategories = results(for: fetchRequest)

            if let position = expenseCategories.firstIndex(of: toEdit) {
                expenseCategories.remove(at: position)
            }

            var emojiArray = [String]()
            var nameArray = [String]()

            expenseCategories.forEach { category in
                emojiArray.append(category.wrappedEmoji)
                nameArray.append(category.wrappedName)
            }

            if emojiArray.contains(emoji) && nameArray.contains(name) {
                return (CategoryError.duplicate, 0)
            } else if emojiArray.contains(emoji) {
                return (CategoryError.duplicateEmoji, 0)
            } else if nameArray.contains(name) {
                return (CategoryError.duplicateName, 0)
            } else {
                let newItemOrder = (expenseCategories.last?.order ?? 0) + 1
                return (CategoryError.none, newItemOrder)
            }
        }
    }

    func fetchRequestForBudgets() -> NSFetchRequest<Budget> {
        let itemRequest: NSFetchRequest<Budget> = Budget.fetchRequest()

        return itemRequest
    }

    func fetchRequestForMainBudget() -> NSFetchRequest<MainBudget> {
        let itemRequest: NSFetchRequest<MainBudget> = MainBudget.fetchRequest()

        return itemRequest
    }

    func fetchRequestForLogView(type: Int, optionalIncome: Bool?, categoryFilters: [Category] = []) -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        let dateCapPredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)

        // all time
        if type == 5 {
            let andPredicate: NSCompoundPredicate
            let superPredicate: NSCompoundPredicate

            var categoryPredicates = [NSPredicate]()

            for category in categoryFilters {
                categoryPredicates.append(NSPredicate(format: "%K == %@", #keyPath(Transaction.category), category))
            }

            let categoryCompoundPredicate = NSCompoundPredicate(type: .or, subpredicates: categoryPredicates)

            if let income = optionalIncome {
                let incomePredicate = NSPredicate(format: "income = %d", income)

                andPredicate = NSCompoundPredicate(type: .and, subpredicates: [incomePredicate, dateCapPredicate])

                superPredicate = NSCompoundPredicate(type: .and, subpredicates: [andPredicate, categoryCompoundPredicate])
            } else {
                andPredicate = NSCompoundPredicate(type: .and, subpredicates: [dateCapPredicate])

                superPredicate = NSCompoundPredicate(type: .and, subpredicates: [andPredicate, categoryCompoundPredicate])
            }

            if categoryFilters.isEmpty {
                itemRequest.predicate = andPredicate
            } else {
                itemRequest.predicate = superPredicate
            }

            return itemRequest
        } else {
            let startPredicate: NSPredicate

            if type == 1 {
                let today = calendar.startOfDay(for: Date.now)
                startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), today as CVarArg)
            } else if type == 2 {
                let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date.now)
                let thisWeek = calendar.date(from: dateComponents)!
                startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), thisWeek as CVarArg)
            } else if type == 3 {
                let startOfMonth = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstDayOfMonth")

                let thisMonth = getStartOfMonth(startDay: startOfMonth)
                startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), thisMonth as CVarArg)
            } else {
                let dateComponents = calendar.dateComponents([.year], from: Date.now)
                let thisYear = calendar.date(from: dateComponents)!
                startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), thisYear as CVarArg)
            }

            let andPredicate: NSCompoundPredicate
            let superPredicate: NSCompoundPredicate

            var categoryPredicates = [NSPredicate]()

            for category in categoryFilters {
                categoryPredicates.append(NSPredicate(format: "%K == %@", #keyPath(Transaction.category), category))
            }

            let categoryCompoundPredicate = NSCompoundPredicate(type: .or, subpredicates: categoryPredicates)

            if let income = optionalIncome {
                let incomePredicate = NSPredicate(format: "income = %d", income)

                andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, incomePredicate, dateCapPredicate])

                superPredicate = NSCompoundPredicate(type: .and, subpredicates: [andPredicate, categoryCompoundPredicate])
            } else {
                andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, dateCapPredicate])

                superPredicate = NSCompoundPredicate(type: .and, subpredicates: [andPredicate, categoryCompoundPredicate])
            }

            if categoryFilters.isEmpty {
                itemRequest.predicate = andPredicate
            } else {
                itemRequest.predicate = superPredicate
            }

            return itemRequest
        }

    }

    func getShortcutInsights(type: Int, timeframe: Int, optionalIncome: Bool?, categories: [Category]) -> Double {
        let fetchRequest = fetchRequestForLogView(type: timeframe, optionalIncome: optionalIncome, categoryFilters: categories)
        let allTransactions = results(for: fetchRequest)

        if type == 1 {
            var total = 0.0

            allTransactions.forEach { transaction in
                if transaction.income {
                    total += transaction.amount
                } else {
                    total -= transaction.amount
                }
            }

            return total
        } else {
            var total = 0.0

            allTransactions.forEach { transaction in
                total += transaction.amount
            }

            return total
        }
    }

    func getLogViewTotalSpent(type: Int) -> Double {
        let fetchRequest = fetchRequestForLogView(type: type, optionalIncome: false)
        let allTransactions = results(for: fetchRequest)

        var total = 0.0

        allTransactions.forEach { transaction in
            total += transaction.amount
        }

        return total
    }

    func getLogViewTotalIncome(type: Int) -> Double {
        let fetchRequest = fetchRequestForLogView(type: type, optionalIncome: true)
        let allTransactions = results(for: fetchRequest)

        var total = 0.0

        allTransactions.forEach { transaction in
            total += transaction.amount
        }

        return total
    }

    func getLogViewTotalNet(type: Int) -> (value: Double, positive: Bool) {
        let fetchRequest = fetchRequestForLogView(type: type, optionalIncome: nil)
        let allTransactions = results(for: fetchRequest)

        var total = 0.0

        allTransactions.forEach { transaction in
            if transaction.income {
                total += transaction.amount
            } else {
                total -= transaction.amount
            }
        }

        if total >= 0 {
            return (total, true)
        } else {
            return (abs(total), false)
        }
    }

    func getLineGraphDataNet(type: Int) -> [LineGraphDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        let fetchRequest = fetchRequestForLineGraph(optionalIncome: nil)
        let transactions = results(for: fetchRequest)

        var holdingDataPoints = [LineGraphDataPoint]()
        var totalForDay = 0.0

        if type < 3 {
            let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            var changingDate = Calendar.current.date(byAdding: .second, value: 86399, to: lastWeek)!

            for transaction in transactions {
                if transaction.wrappedDate < changingDate {
                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                } else {
                    let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                    holdingDataPoints.append(newData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                    while transaction.wrappedDate > changingDate {
                        let anotherNewData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                        holdingDataPoints.append(anotherNewData)
                        changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                    }

                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                }
            }

            let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < today {
                changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                while changingDate < today {
                    let anotherNewData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: totalForDay)
                holdingDataPoints.append(finalDate)
            }
        } else if type == 3 {
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!
            var changingDate = Calendar.current.date(byAdding: .second, value: 86399, to: lastMonth)!

            for transaction in transactions {
                if transaction.wrappedDate < changingDate {
                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                } else {
                    let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                    holdingDataPoints.append(newData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                    while transaction.wrappedDate > changingDate {
                        let anotherNewData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                        holdingDataPoints.append(anotherNewData)
                        changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                    }

                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                }
            }

            let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < today {
                changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                while changingDate < today {
                    let anotherNewData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: totalForDay)
                holdingDataPoints.append(finalDate)
            }
        } else if type == 4 {
            let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)
            let thisMonth = calendar.date(from: dateComponents)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: thisMonth)!
            var changingDate = calendar.date(byAdding: .year, value: -1, to: nextMonth)!

            for transaction in transactions {
                if transaction.wrappedDate < changingDate {
                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                } else {
                    let dataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                    let newData = LineGraphDataPoint(date: dataDate, amount: totalForDay)
                    holdingDataPoints.append(newData)
                    changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!

                    while transaction.wrappedDate > changingDate {
                        let newDataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                        let anotherNewData = LineGraphDataPoint(date: newDataDate, amount: totalForDay)
                        holdingDataPoints.append(anotherNewData)
                        changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                    }

                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                }
            }

            let dataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
            let newData = LineGraphDataPoint(date: dataDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < nextMonth {
                changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!

                while changingDate < nextMonth {
                    let anotherDataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                    let anotherNewData = LineGraphDataPoint(date: anotherDataDate, amount: totalForDay)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: totalForDay)
                holdingDataPoints.append(finalDate)
            }
        }

        return holdingDataPoints
    }

    func getLineGraphData(income: Bool, type: Int) -> [LineGraphDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        let fetchRequest = fetchRequestForLineGraph(optionalIncome: income)
        let transactions = results(for: fetchRequest)

        var holdingDataPoints = [LineGraphDataPoint]()
        var totalForDay = 0.0

        if type < 3 {
            let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            var changingDate = Calendar.current.date(byAdding: .second, value: 86399, to: lastWeek)!

            for transaction in transactions {
                if transaction.wrappedDate > lastWeek {
                    if transaction.wrappedDate < changingDate {
                        totalForDay += transaction.wrappedAmount
                    } else {
                        let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                        holdingDataPoints.append(newData)
                        changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                        totalForDay = 0

                        while transaction.wrappedDate > changingDate {
                            let anotherNewData = LineGraphDataPoint(date: changingDate, amount: 0)
                            holdingDataPoints.append(anotherNewData)
                            changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                        }

                        totalForDay += transaction.wrappedAmount
                    }
                }
            }

            let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
            holdingDataPoints.append(newData)
            totalForDay = 0

            if changingDate < today {
                changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                while changingDate < today {
                    let anotherNewData = LineGraphDataPoint(date: changingDate, amount: 0)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: totalForDay)
                holdingDataPoints.append(finalDate)
            }
        } else if type == 3 {
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!
            var changingDate = Calendar.current.date(byAdding: .second, value: 86399, to: lastMonth)!

            for transaction in transactions {
                if transaction.wrappedDate > lastMonth {
                    if transaction.wrappedDate < changingDate {
                        totalForDay += transaction.wrappedAmount
                    } else {
                        let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                        holdingDataPoints.append(newData)
                        changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                        totalForDay = 0

                        while transaction.wrappedDate > changingDate {
                            let anotherNewData = LineGraphDataPoint(date: changingDate, amount: 0)
                            holdingDataPoints.append(anotherNewData)
                            changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                        }

                        totalForDay += transaction.wrappedAmount
                    }
                }
            }

            let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < today {
                changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                while changingDate < today {
                    let anotherNewData = LineGraphDataPoint(date: changingDate, amount: 0)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: 0)
                holdingDataPoints.append(finalDate)
            }
        } else if type == 4 {
            let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)
            let thisMonth = calendar.date(from: dateComponents)!
            let thisMonthLastYear = calendar.date(byAdding: .year, value: -1, to: thisMonth)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: thisMonth)!
            var changingDate = calendar.date(byAdding: .year, value: -1, to: nextMonth)!

            for transaction in transactions {
                if transaction.wrappedDate > thisMonthLastYear {
                    if transaction.wrappedDate < changingDate {
                        totalForDay += transaction.wrappedAmount
                    } else {
                        let dataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                        let newData = LineGraphDataPoint(date: dataDate, amount: totalForDay)
                        holdingDataPoints.append(newData)
                        changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                        totalForDay = 0

                        while transaction.wrappedDate > changingDate {
                            let newDataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                            let anotherNewData = LineGraphDataPoint(date: newDataDate, amount: 0)
                            holdingDataPoints.append(anotherNewData)
                            changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                        }

                        totalForDay += transaction.wrappedAmount
                    }
                }
            }

            let dataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
            let newData = LineGraphDataPoint(date: dataDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < nextMonth {
                changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!

                while changingDate < nextMonth {
                    let anotherDataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                    let anotherNewData = LineGraphDataPoint(date: anotherDataDate, amount: 0)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: 0)
                holdingDataPoints.append(finalDate)
            }
        }

        return holdingDataPoints
    }

    func getBudgetLeftover(budget: Budget? = nil, overallBudget: MainBudget? = nil) -> Double {
        let itemRequest: NSFetchRequest<Transaction>
        let budgetAmount: Double

        if let unwrappedOverallBudget = overallBudget {
            itemRequest = fetchRequestForMainBudgetTransactions(budget: unwrappedOverallBudget)
            budgetAmount = unwrappedOverallBudget.amount
        } else if let unwrappedBudget = budget {
            itemRequest = fetchRequestForBudgetTransactions(budget: unwrappedBudget)
            budgetAmount = unwrappedBudget.amount
        } else {
            itemRequest = Transaction.fetchRequest()
            budgetAmount = 0
        }

        let transactions = results(for: itemRequest)

        var totalSpent = 0.0

        transactions.forEach { transaction in
            totalSpent += transaction.wrappedAmount
        }

        return budgetAmount - totalSpent
    }

    func fetchRequestForMainBudgetTransactions(budget: MainBudget) -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), budget.startDate! as CVarArg)
        let endPredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)
        let incomePredicate = NSPredicate(format: "income = %d", false)

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, incomePredicate])

        itemRequest.predicate = andPredicate

        return itemRequest
    }

    func fetchRequestForBudgetTransactions(budget: Budget) -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), budget.startDate! as CVarArg)
        let endPredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)
        let categoryPredicate = NSPredicate(format: "%K == %@", #keyPath(Transaction.category), budget.category!)
        let incomePredicate = NSPredicate(format: "income = %d", false)

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, categoryPredicate, incomePredicate])

        itemRequest.predicate = andPredicate

        return itemRequest
    }

    func fetchRequestForLineGraph(optionalIncome: Bool?) -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        itemRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: true)]

        if let income = optionalIncome {
            itemRequest.predicate = NSPredicate(format: "income = %d", income)
            return itemRequest
        } else {
            return itemRequest
        }
    }

    func fetchRequestForLogViewCategoryFilter(income: Bool) -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "income = %d", income)
        return itemRequest
    }

    func getInsights(type: Int, date: Date, income: Bool) -> (amount: Double, maximum: Double, average: Double, numberOfDays: Int, dates: [Date], dateDictionary: [Date: Double]) {
        let currentItemRequest: NSFetchRequest<Transaction> = fetchRequestForInsights(type: type, date: date, income: income)
        let currentTransactions = results(for: currentItemRequest)

        var iterativeDate = date

        if type == 1 {
            // tracking dates
            var dates = [Date]()
            var nextDate = date

            // calendar initialization
            var calendar = Calendar(identifier: .gregorian)

            calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
            calendar.minimumDaysInFirstWeek = 4

            var dictionary = [Date: Double]()
            var totalForWeek = 0.0
            var maximum = 0.0
            var numberOfDays = 0
            var weekAverage = 0.0

            for _ in 1 ... 7 {
                nextDate = calendar.date(byAdding: .day, value: 1, to: iterativeDate)!

                let holding = currentTransactions.filter {
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

            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date.now)

            let currentWeek = calendar.date(from: dateComponents)!

            if currentWeek == date {
//                let fromDate = Calendar.current.startOfDay(for: currentWeek)
//                let toDate = Calendar.current.startOfDay(for: Date.now)
                let numberOfDays = Calendar.current.dateComponents([.day], from: currentWeek, to: Date.now)

                weekAverage = totalForWeek / Double((numberOfDays.day! + 1))
            } else {
                weekAverage = totalForWeek / 7
            }

            return (totalForWeek, maximum, weekAverage, numberOfDays, dates, dictionary)
        } else if type == 2 {
            // tracking dates
            var dates = [Date]()
            var nextDate = date

            let calendar = Calendar(identifier: .gregorian)
            let range = calendar.range(of: .day, in: .month, for: iterativeDate)!

            var dictionary = [Date: Double]()
            var totalForMonth = 0.0
            var maximum = 0.0
            var numberOfDays = 0
            var monthAverage = 0.0

            for _ in 1 ... range.count {
                nextDate = calendar.date(byAdding: .day, value: 1, to: iterativeDate)!

                let holding = currentTransactions.filter {
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

            let next = calendar.date(byAdding: .month, value: 1, to: date) ?? Date.now

            if next > Date.now {
                let numDays = Calendar.current.dateComponents([.day], from: date, to: Date.now)

                monthAverage = totalForMonth / Double((numDays.day! + 1))
            } else {
                monthAverage = totalForMonth / Double(range.count)
            }

            return (totalForMonth, maximum, monthAverage, numberOfDays, dates, dictionary)
        } else if type == 3 {
            // trackin dates
            var dates = [Date]()
            var nextDate = date

            let calendar = Calendar(identifier: .gregorian)

            var dictionary = [Date: Double]()
            var totalForYear = 0.0
            var maximum = 0.0
            var numberOfDays = 0
            var monthAverage = 0.0

            for _ in 1 ... 12 {
                nextDate = calendar.date(byAdding: .month, value: 1, to: iterativeDate)!

                let holding = currentTransactions.filter {
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

            let dateComponents = calendar.dateComponents([.year], from: Date.now)

            let currentYear = calendar.date(from: dateComponents)!

            if currentYear == date {
                let fromDate = Calendar.current.startOfDay(for: currentYear)
                let toDate = Calendar.current.startOfDay(for: Date.now)
                let numDays = Calendar.current.dateComponents([.month], from: fromDate, to: toDate)

                monthAverage = totalForYear / Double((numDays.month! + 1))
            } else {
                monthAverage = totalForYear / 12
            }

            return (totalForYear, maximum, monthAverage, numberOfDays, dates, dictionary)
        } else {
            return (0, 0, 0, 0, [Date](), [Date: Double]())
        }
    }

    func fetchRequestForInsights(type: Int, date: Date, income: Bool? = nil) -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), date as CVarArg)

        let endPredicate: NSPredicate

        if type == 1 {
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .weekOfYear) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .day, value: 7, to: date) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        } else if type == 2 {
            let next = calendar.date(byAdding: .month, value: 1, to: date) ?? Date.now

//            let endOfPeriod = calendar.date(byAdding: .day, value: -1, to: next) ?? Date.now
//
            if next > Date.now {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
//
//            if calendar.isDate(date, equalTo: Date.now, toGranularity: .month) {
//                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
//            } else {
//
//                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
//            }
        } else {
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .year) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .year, value: 1, to: date) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        }

        let andPredicate: NSCompoundPredicate

        if let unwrappedIncome = income {
            let incomePredicate = NSPredicate(format: "income = %d", unwrappedIncome)

            andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, incomePredicate, endPredicate])
        } else {
            andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])
        }

        itemRequest.predicate = andPredicate

        return itemRequest
    }

    func getInsightsSummary(type: Int, date: Date) -> (spent: Double, income: Double, net: Double, positive: Bool, average: Double) {
        let itemRequest: NSFetchRequest<Transaction> = fetchRequestForInsights(type: type, date: date)
        let currentTransactions = results(for: itemRequest)

        var holdingSpent = 0.0
        var holdingIncome = 0.0

        currentTransactions.forEach { transaction in
            if transaction.income {
                holdingIncome += transaction.amount
            } else {
                holdingSpent += transaction.amount
            }
        }

        let net = holdingIncome - holdingSpent
        let absoluteNet: Double
        let positive: Bool

        if net < 0 {
            absoluteNet = abs(net)
            positive = false
        } else {
            absoluteNet = net
            positive = true
        }

        let calendar = Calendar.current

        if type == 1 {
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .weekOfYear) {
                let numberOfDays = Calendar.current.dateComponents([.day], from: date, to: Date.now)

                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numberOfDays.day! + 1))
            } else {
                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / 7)
            }
        } else if type == 2 {
            let next = calendar.date(byAdding: .month, value: 1, to: date) ?? Date.now

            if next > Date.now {
                let numDays = Calendar.current.dateComponents([.day], from: date, to: Date.now)

                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays.day! + 1))
            } else {
                let numDays = Calendar.current.dateComponents([.day], from: date, to: next)

                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays.day! + 1))
            }
//            if calendar.isDate(date, equalTo: Date.now, toGranularity: .month) {
//                let numDays = Calendar.current.dateComponents([.day], from: date, to: Date.now)
//
//                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays.day! + 1))
//            } else {
//
//                let range = calendar.range(of: .day, in: .month, for: date)!
//                let numDays = range.count
//
//                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays))
//            }
        } else {
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .year) {
                let numDays = Calendar.current.dateComponents([.month], from: date, to: Date.now)

                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays.month! + 1))
            } else {
                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / 12)
            }
        }
    }

    func fetchRequestForWidgetInsights(type: InsightsTimePeriod, income: Bool) -> (fetchRequest: NSFetchRequest<Transaction>, date: Date) {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        let endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)

        let incomePredicate = NSPredicate(format: "income = %d", income)

        let startDate: Date
        let startPredicate: NSPredicate

        switch type {
        case .unknown:
            startDate = Date.now
            startPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
        case .week:
            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date.now)

            startDate = calendar.date(from: dateComponents)!

            startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), startDate as CVarArg)
        case .month:
            let startOfMonth = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstDayOfMonth")

            startDate = getStartOfMonth(startDay: startOfMonth)

            startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), startDate as CVarArg)
        case .year:
            let dateComponents = calendar.dateComponents([.year], from: Date.now)

            startDate = calendar.date(from: dateComponents)!

            startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), startDate as CVarArg)
        }

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, incomePredicate])

        itemRequest.predicate = andPredicate
        itemRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
        ]

        return (itemRequest, startDate)
    }

    func fetchRequestForRecentTransactionsWithCount(type: TimePeriod, count: Int) -> NSFetchRequest<Transaction> {
        let itemRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        switch type {
        case .unknown:
            return itemRequest
        case .day:
            let today = calendar.startOfDay(for: Date.now)

            let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), today as CVarArg)
            let endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])

            itemRequest.predicate = andPredicate
            itemRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]
            itemRequest.fetchLimit = count

            return itemRequest
        case .week:
            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date.now)

            let thisWeek = calendar.date(from: dateComponents)!

            let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), thisWeek as CVarArg)
            let endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])

            itemRequest.predicate = andPredicate
            itemRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]
            itemRequest.fetchLimit = count

            return itemRequest
        case .month:
            let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)

            let thisMonth = calendar.date(from: dateComponents)!

            let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), thisMonth as CVarArg)
            let endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])

            itemRequest.predicate = andPredicate
            itemRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]
            itemRequest.fetchLimit = count

            return itemRequest
        case .year:
            let dateComponents = calendar.dateComponents([.year], from: Date.now)

            let thisYear = calendar.date(from: dateComponents)!

            let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), thisYear as CVarArg)
            let endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate])

            itemRequest.predicate = andPredicate
            itemRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
            ]
            itemRequest.fetchLimit = count

            return itemRequest
        }
    }

    func fetchRequestForMainBudgetWidget() -> (found: Bool, totalSpent: Double, budgetAmount: Double, percentage: Double, type: Int, startDate: Date) {
        let holding = results(for: fetchRequestForMainBudget())

        if let budget = holding.first {
            let itemRequest = fetchRequestForMainBudgetTransactions(budget: budget)
//
            let transactions = results(for: itemRequest)

            var holdingTotal = 0.0
            transactions.forEach { transaction in
                holdingTotal += transaction.wrappedAmount
            }

            let percentageOfDays: Double

            let calendar = Calendar.current

            if budget.type == 1 {
                let components = calendar.dateComponents([.minute], from: budget.startDate!, to: Date.now)
                percentageOfDays = Double(components.minute!) / 1440
            } else {
                let components1 = calendar.dateComponents([.day], from: budget.startDate!, to: budget.endDate)
                let numberOfDays = components1.day!

                let components2 = calendar.dateComponents([.day], from: budget.startDate!, to: Date.now)
                let numberOfDaysPast = components2.day!

                percentageOfDays = Double(numberOfDaysPast) / Double(numberOfDays)
            }

            return (true, holdingTotal, budget.amount, percentageOfDays, Int(budget.type), budget.startDate!)

        } else {
            return (false, 0, 0, 0, 0, Date.now)
        }
    }

    func results<T: NSManagedObject>(for fetchRequest: NSFetchRequest<T>) -> [T] {
        return (try? container.viewContext.fetch(fetchRequest)) ?? []
    }
}

public extension NSManagedObjectContext {
    func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}

struct LineGraphDataPoint: Equatable {
    let date: Date
    let amount: Double

    var dateString: String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "d MMM"

        return dateFormatter.string(from: date)
    }

    var monthString: String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "MMM yy"

        return dateFormatter.string(from: date)
    }

    var amountString: String {
        if abs(amount) < 1000 {
            return String(format: "%.2f", amount)
        } else {
            return String(format: "%.0f", amount)
        }
    }
}

func getStartOfMonth(startDay: Int) -> Date {
    let calendar = Calendar.current

    guard startDay > 0 && startDay <= calendar.maximumRange(of: .day)!.upperBound else {
        let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)
        return calendar.date(from: dateComponents) ?? Date.now
    }

    let today = calendar.startOfDay(for: Date.now)
    let currentDay = calendar.component(.day, from: today)

    var startComponents = DateComponents()
    startComponents.month = currentDay >= startDay ? 0 : -1

    startComponents.day = startDay - currentDay

    return calendar.date(byAdding: startComponents, to: today) ?? Date.now
}

func calculateStartOfMonthPeriod(earliestDate: Date, startOfMonthDay: Int) -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: earliestDate)
    components.day = startOfMonthDay

    let startOfMonth = Calendar.current.date(from: components) ?? Date.now
    return (earliestDate < startOfMonth) ? (Calendar.current.date(byAdding: .month, value: -1, to: startOfMonth) ?? Date.now) : startOfMonth
}
