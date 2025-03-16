//
//  Helper.swift
//  dime
//
//  Created by Rafael Soh on 13/8/22.
//

import Foundation

extension Transaction {
    var wrappedAmount: Double {
        amount
    }

    var wrappedDate: Date {
        date ?? Date.now
    }

    var wrappedNote: String {
        note ?? ""
    }

    var wrappedCategoryName: String {
        category?.wrappedName ?? ""
    }

    var wrappedColour: String {
        category?.wrappedColour ?? ""
    }

    var nextTransactionDate: Date {
        if recurringType == 1 {
            return Calendar.current.date(byAdding: .day, value: Int(recurringCoefficient), to: day ?? Date.now)!
        } else if recurringType == 2 {
            return Calendar.current.date(byAdding: .day, value: Int(recurringCoefficient * 7), to: day ?? Date.now)!
        } else if recurringType == 3 {
            return Calendar.current.date(byAdding: .month, value: Int(recurringCoefficient), to: day ?? Date.now)!
        }

        return date ?? Date.now
    }
}

extension TemplateTransaction {
    var wrappedAmount: Double {
        amount
    }

    var wrappedNote: String {
        note ?? ""
    }

    var wrappedEmoji: String {
        category?.wrappedEmoji ?? ""
    }

    var wrappedColour: String {
        category?.wrappedColour ?? ""
    }
}

extension Category {
    var wrappedColour: String {
        colour ?? "#FFFFFF"
    }

    var wrappedEmoji: String {
        emoji ?? "😄️"
    }

    var wrappedName: String {
        name ?? ""
    }

    var wrappedDate: Date {
        dateCreated ?? Date.now
    }

    var fullName: String {
        wrappedEmoji + "  " + wrappedName
    }

    var allTransactions: [Transaction] {
        let set = transactions as? Set<Transaction> ?? []
        return set.sorted {
            $0.wrappedDate < $1.wrappedDate
        }
    }

    var transactionCount: Int {
        transactions?.count ?? 0
    }
}

public extension Budget {
    var wrappedColour: String {
        category?.wrappedColour ?? "#FFFFFF"
    }

    var wrappedName: String {
        category?.wrappedName ?? ""
    }

    var wrappedEmoji: String {
        category?.wrappedEmoji ?? ""
    }

    var fullName: String {
        return wrappedEmoji + " " + wrappedName
    }

    var wrappedDate: Date {
        return startDate ?? Date.now
    }

    var endDate: Date {
        if type == 1 {
            return Calendar.current.date(byAdding: .day, value: 1, to: startDate ?? Date.now)!
        } else if type == 2 {
            return Calendar.current.date(byAdding: .day, value: 7, to: startDate ?? Date.now)!
        } else if type == 3 {
            return Calendar.current.date(byAdding: .month, value: 1, to: startDate ?? Date.now)!
        } else if type == 4 {
            return Calendar.current.date(byAdding: .year, value: 1, to: startDate ?? Date.now)!
        }
        return startDate ?? Date.now
    }
}

public extension MainBudget {
    var wrappedDate: Date {
        return startDate ?? Date.now
    }

    var endDate: Date {
        if type == 1 {
            return Calendar.current.date(byAdding: .day, value: 1, to: startDate ?? Date.now)!
        } else if type == 2 {
            return Calendar.current.date(byAdding: .day, value: 7, to: startDate ?? Date.now)!
        } else if type == 3 {
            return Calendar.current.date(byAdding: .month, value: 1, to: startDate ?? Date.now)!
        } else if type == 4 {
            return Calendar.current.date(byAdding: .year, value: 1, to: startDate ?? Date.now)!
        }

        return startDate ?? Date.now
    }
}
