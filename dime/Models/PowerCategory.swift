//
//  PowerCategory.swift
//  Bonsai
//
//  Created by Rafael Soh on 6/6/22.
//

import Foundation
import SwiftUI

struct PowerCategory: Hashable, Identifiable {
    let id: UUID
    let category: Category
    let percent: Double
    let amount: Double
}

struct SuggestedCategory: Hashable {
    let name: String
    let emoji: String

    static var expenses: [SuggestedCategory] {
        var holding = [SuggestedCategory]()
        let food = SuggestedCategory(name: String(.food), emoji: "🍔")
        holding.append(food)

        let transport = SuggestedCategory(name: String(.transport), emoji: "🚆")
        holding.append(transport)

        let housing = SuggestedCategory(name: String(.rent), emoji: "🏠")
        holding.append(housing)

        let subscriptions = SuggestedCategory(name: String(.subscriptions), emoji: "🔄")
        holding.append(subscriptions)

        let groceries = SuggestedCategory(name: String(.groceries), emoji: "🛒")
        holding.append(groceries)

        let family = SuggestedCategory(name: String(.family), emoji: "👨‍👩‍👦")
        holding.append(family)

        let utilities = SuggestedCategory(name: String(.utilities), emoji: "💡")
        holding.append(utilities)

        let fashion = SuggestedCategory(name: String(.fashion), emoji: "👔")
        holding.append(fashion)

        let healthcare = SuggestedCategory(name: String(.healthcare), emoji: "🚑")
        holding.append(healthcare)

        let pets = SuggestedCategory(name: String(.pets), emoji: "🐕")
        holding.append(pets)

        let sneakers = SuggestedCategory(name: String(.sneakers), emoji: "👟")
        holding.append(sneakers)

        let gifts = SuggestedCategory(name: String(.gifts), emoji: "🎁")
        holding.append(gifts)

        return holding
    }

    static var incomes: [SuggestedCategory] {
        var holding = [SuggestedCategory]()
        let paycheck = SuggestedCategory(name: String(.paycheck), emoji: "💰")
        holding.append(paycheck)

        let allowance = SuggestedCategory(name: String(.allowance), emoji: "🤑")
        holding.append(allowance)

        let parttime = SuggestedCategory(name: String(.partTime), emoji: "💼")
        holding.append(parttime)

        let investments = SuggestedCategory(name: String(.investments), emoji: "💹")
        holding.append(investments)

        let gifts = SuggestedCategory(name: String(.gifts), emoji: "🧧")
        holding.append(gifts)

        let tips = SuggestedCategory(name: String(.tips), emoji: "🪙")
        holding.append(tips)

        return holding
    }
}
