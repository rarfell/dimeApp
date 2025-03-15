//
//  BudgetView.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import CrookedText
import Foundation
import Popovers
import SwiftUI

struct BudgetView: View {
    @FetchRequest(sortDescriptors: []) private var categories: FetchedResults<Category>
    @FetchRequest(sortDescriptors: []) private var budgets: FetchedResults<Budget>
    @FetchRequest(sortDescriptors: []) private var mainBudget: FetchedResults<MainBudget>

    var body: some View {
        if categories.isEmpty && budgets.isEmpty && mainBudget.isEmpty {
            VStack(spacing: 5) {
                Image("category-3")
                    .resizable()
                    .frame(width: 75, height: 75)
                    .padding(.bottom, 20)

                Text("Budget Your Finances")
                    .font(.system(.title2, design: .rounded).weight(.medium))
//                    .font(.system(size: 23.5, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.PrimaryText.opacity(0.8))

                Text("Link budgets to categories and set appropriate expenditure goals")
                    .font(.system(.body, design: .rounded).weight(.medium))
//                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.SubtitleText.opacity(0.7))
            }
            .padding(.horizontal, 30)
            .frame(height: 250, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            .background(Color.PrimaryBackground)

        } else {
            ActualBudgetView()
        }
    }
}

struct ActualBudgetView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showInfo = false

    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.dateCreated)
    ]) private var budgets: FetchedResults<Budget>
    @FetchRequest(sortDescriptors: []) private var mainBudget: FetchedResults<MainBudget>
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var tabBarManager: TabBarManager

    @State var newBudget = false

    @State private var showMenu = false

    @State private var toDelete: Budget?
    @State private var toEdit: Budget?

    let layout = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]

    @AppStorage("budgetViewStyle", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var budgetRows: Bool = false

    @Namespace var animation

    var didSave = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave) // the publisher
    @AppStorage("UUID") var refreshID = UUID().uuidString

    @State var date = Date.now

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Budgets")
                        .font(.system(.title, design: .rounded).weight(.semibold))
//                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .accessibility(addTraits: .isHeader)

                    Button {
                        newBudget = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
//                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(4)
                            .background(Color.SecondaryBackground, in: Circle())
                            .contentShape(Circle())
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)

                if !budgets.isEmpty || !mainBudget.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack {
                            if let first = mainBudget.first {
                                NavigationLink(destination: DetailedMainBudgetView(budget: first)
                                    .onAppear {
                                        withAnimation(.easeOut.speed(2)) {
                                            tabBarManager.navigationHideTab()
                                        }
                                    }
                                    .onDisappear {
                                        withAnimation(.easeOut.speed(2)) {
                                            tabBarManager.navigationShowTab()
                                        }
                                    }

                                ) {
                                    if budgets.count == 0 {
                                        MainBudgetView(budget: first, solo: true)
                                            .padding(.horizontal, 25)
                                            .padding(.bottom, 15)
                                            .id(refreshID)
                                    } else {
                                        MainBudgetView(budget: first, solo: false)
                                            .padding(.horizontal, 25)
                                            .padding(.bottom, 15)
                                            .id(refreshID)
                                    }
                                }
                            }

                            if budgetRows {
                                VStack(spacing: 10) {
                                    ForEach(budgets, id: \.self) { budget in
                                        NavigationLink(destination: DetailedBudgetView(budget: budget)
                                            .onAppear {
                                                withAnimation(.easeOut.speed(2)) {
                                                    tabBarManager.navigationHideTab()
                                                }
                                            }
                                            .onDisappear {
                                                withAnimation(.easeOut.speed(2)) {
                                                    tabBarManager.navigationShowTab()
                                                }
                                            }

                                        ) {
                                            SingleBudgetView(budget: budget, toDelete: $toDelete, toEdit: $toEdit, budgetRows: budgetRows)
                                        }
                                    }
                                }

                            } else {
                                LazyVGrid(columns: layout, spacing: 15) {
                                    ForEach(budgets, id: \.self) { budget in
                                        NavigationLink(destination: DetailedBudgetView(budget: budget)
                                            .onAppear {
                                                withAnimation(.easeOut.speed(2)) {
                                                    tabBarManager.navigationHideTab()
                                                }
                                            }
                                            .onDisappear {
                                                withAnimation(.easeOut.speed(2)) {
                                                    tabBarManager.navigationShowTab()
                                                }
                                            }

                                        ) {
                                            SingleBudgetView(budget: budget, toDelete: $toDelete, toEdit: $toEdit, budgetRows: budgetRows)
                                        }
                                    }
                                }
                                .padding(.horizontal, 25)
                                .padding(5)
                            }
                        }
                        .padding(.bottom, 70)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(refreshID)
                } else {
                    VStack(spacing: 5) {
                        Spacer()
                        Text("🙈")
                            .font(.system(.largeTitle, design: .rounded))
//                            .font(.system(size: 45))
                            .padding(.bottom, 9)

                        Text("No Budgets Found")
                            .font(.system(.title2, design: .rounded).weight(.medium))
//                            .font(.system(size: 23.5, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.PrimaryText.opacity(0.8))

                        Text("Add your first budget today!")
                            .font(.system(.body, design: .rounded).weight(.medium))
//                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.SubtitleText.opacity(0.7))

                        Spacer()
                        Spacer()
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .background(Color.PrimaryBackground)
            .sheet(item: $toEdit, onDismiss: {
                toEdit = nil
            }) { budget in
                BrandNewBudgetView(overallBudgetCreated: !mainBudget.isEmpty, toEditBudget: budget)
            }
            .onAppear {
                dataController.updateBudgetDates()
            }
            .sheet(isPresented: $newBudget) {
                BrandNewBudgetView(overallBudgetCreated: !mainBudget.isEmpty)
            }
            .fullScreenCover(item: $toDelete, onDismiss: {
                toDelete = nil
            }) { budget in
                DeleteBudgetAlert(toDelete: budget)
            }
            .onReceive(self.didSave) { _ in // the listener
                withAnimation {
                    refreshID = UUID().uuidString
                }
            }
        }
    }
}

struct MainBudgetView: View {
    let budget: MainBudget
    @FetchRequest<Transaction> private var transactions: FetchedResults<Transaction>

    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController

    @State var toEdit: MainBudget?
    @State var toDelete: MainBudget?
    @State var totalSpent: Double = 0

    var soloBudget: Bool

    var budgetAmount: Double {
        if budget.isFault {
            return 0.0
        }

        return budget.amount
    }

    var budgetType: String {
        if budget.isFault {
            return ""
        }

        switch budget.type {
        case 1:
            return String(localized: "today")
        case 2:
            return String(localized: "this week")
        case 3:
            return String(localized: "this month")
        case 4:
            return String(localized: "this year")
        default:
            return "this week"
        }
    }

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var percentageOfDays: Double {
        let calendar = Calendar.current

        if budget.isFault {
            return 0.0
        }

        if budget.type == 1 {
            let components = calendar.dateComponents([.minute], from: budget.wrappedDate, to: Date.now)
            return Double(components.minute ?? 0) / 1440
        }

        let components1 = calendar.dateComponents([.day], from: budget.wrappedDate, to: budget.endDate)
        let numberOfDays = components1.day ?? 0

        let components2 = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
        let numberOfDaysPast = components2.day ?? 0

        return Double(numberOfDaysPast) / Double(numberOfDays)
    }

    var targetPercent: Double {
        let calendar = Calendar.current

        if budget.isFault {
            return 0.0
        }

        let components1 = calendar.dateComponents([.day], from: budget.wrappedDate, to: budget.endDate)
        let numberOfDays = components1.day ?? 0

        let components2 = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
        let numberOfDaysPast = (components2.day ?? 0) + 1

        return Double(numberOfDays - numberOfDaysPast) / Double(numberOfDays)
    }

    var triangleOffset: (x: Double, y: Double) {
        var x = 0.0
        var y = -5.0

        let radius = (width / 2) - 5

        if targetPercent > 0.5 {
            let angle = (CGFloat.pi) * (1 - targetPercent)
            y += (radius - (radius * sin(angle)))
            x += (radius * cos(angle))
        } else if targetPercent < 0.5 {
            let angle = (CGFloat.pi) * targetPercent
            y += (radius - (radius * sin(angle)))
            x -= (radius * cos(angle))
        }

        return (x, y)
    }

    var triangleRotation: Double {
        if targetPercent > 0.5 {
            return ((targetPercent - 0.5) / 0.5) * 90
        } else if targetPercent < 0.5 {
            return -((0.5 - targetPercent) / 0.5) * 90
        } else {
            return 0
        }
    }

    var difference: Double {
        return abs(budgetAmount - totalSpent)
    }

    var percentString: String {
        if !budget.isFault {
            return "\(Int(round(100 - (totalSpent / budgetAmount) * 100)))%"
        } else {
            return ""
        }
    }

    var percentString1: String {
        if !budget.isFault {
            return "\(Int(round((totalSpent / budgetAmount) * 100)))%"
        } else {
            return ""
        }
    }

    var width: CGFloat {
        if soloBudget {
            return UIScreen.main.bounds.width - 90
        } else {
            return 250
        }
    }

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .bottom) {
                ZStack {
                    DonutSemicircle(percent: 1, cornerRadius: 6.5, width: soloBudget ? 35 : 25)
                        .fill(Color.SecondaryBackground)
                        .frame(width: width, height: width / 2)

                    if totalSpent / budgetAmount < 0.97 {
                        AnimatedCurvedBarGraphMainBudget(transactions: transactions, budgetTotal: budgetAmount, cornerRadius: 6.5, width: soloBudget ? 35 : 25)
                            .frame(width: width, height: width / 2)
                    }
                }
                .overlay(alignment: .top) {
                    if budget.type != 1 && totalSpent < budgetAmount && targetPercent > 0 {
                        RoundedTriangle(cornerRadius: 2)

                            .fill((targetPercent * budgetAmount) < (budgetAmount - totalSpent) ? Color.SubtitleText : Color.BudgetRed)
                            .frame(width: 20, height: 10)
                            .rotationEffect(Angle(degrees: triangleRotation), anchor: .bottom)
                            .offset(x: triangleOffset.x, y: triangleOffset.y)
                    }
                }

                CrookedText(text: String(localized: "OVERALL SPENT: \(percentString1)"), radius: width / 2 + 8)
                    .font(.system(.footnote, design: .rounded).weight(.medium))
//                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .frame(width: width, height: 10)

                VStack(spacing: -4) {
                    let internalWidth = soloBudget ? width - 90 : width - 60
                    BudgetDollarView(amount: difference, red: totalSpent >= budgetAmount, scale: 3, size: internalWidth)
                        .frame(width: internalWidth)

                    Text("\(budgetAmount >= totalSpent ? "left" : "over") \(budgetType)")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
//                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                }
            }

            HStack {
                if totalSpent < 1000 && budgetAmount < 1000 {
                    Text("\(totalSpent, specifier: "%.2f")")
                        .frame(width: 60, alignment: .leading)
                    Spacer()
                    Text("\(budgetAmount, specifier: "%.2f")")
                        .frame(width: 60, alignment: .trailing)
                } else {
                    Text("\(Int(round(totalSpent)))")
                        .frame(width: 60, alignment: .leading)
                    Spacer()
                    Text("\(Int(round(budgetAmount)))")
                        .frame(width: 60, alignment: .trailing)
                }
            }
            .font(.system(.caption2, design: .rounded).weight(.medium))
//            .font(.system(size: 10, weight: .medium, design: .rounded))
            .frame(width: width)
            .foregroundColor(Color.SubtitleText)
        }
        .padding(.bottom)
        .frame(width: width + 30, height: soloBudget ? 230 : 200, alignment: .bottom)
        .background(soloBudget ? Color.Outline.opacity(0.2) : Color.PrimaryBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 13))
        .contextMenu {
            Button {
                toEdit = budget

            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button {
                toDelete = budget

            } label: {
                Label("Delete", systemImage: "xmark.bin")
            }
        }
        .onAppear {
            if budget.isFault {
                return
            }

            var holdingTotal = 0.0
            transactions.forEach { transaction in
                holdingTotal += transaction.wrappedAmount
            }

            totalSpent = holdingTotal
        }
        .sheet(item: $toEdit, onDismiss: {
            toEdit = nil
        }) { budget in
            BrandNewBudgetView(overallBudgetCreated: true, toEditMainBudget: budget)
        }
        .fullScreenCover(item: $toDelete, onDismiss: {
            toDelete = nil
        }) { budget in
            DeleteMainBudgetAlert(toDelete: budget)
        }
    }

    init(budget: MainBudget, solo: Bool) {
        self.budget = budget
        soloBudget = solo

        let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), budget.wrappedDate as CVarArg)
        let endPredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)
        let incomePredicate = NSPredicate(format: "income = %d", false)

        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, incomePredicate])

        _transactions = FetchRequest<Transaction>(sortDescriptors: [], predicate: andPredicate)
    }
}

struct SingleBudgetView: View {
    let budget: Budget
    @FetchRequest<Transaction> private var transactions: FetchedResults<Transaction>

    @Binding var toDelete: Budget?
    @Binding var toEdit: Budget?

    @State var totalSpent: Double = 0

    var budgetRows: Bool

    var width: CGFloat {
        ((UIScreen.main.bounds.width - 75) / 2) - 30
    }

    var rowWidth: CGFloat {
        (UIScreen.main.bounds.width - 80) / 2
    }

    var budgetAmount: Double {
        if budget.isFault {
            return 0.0
        }

        return budget.amount
    }

    var budgetType: String {
        if budget.isFault {
            return ""
        }

        switch budget.type {
        case 1:
            return String(localized: "today")
        case 2:
            return String(localized: "this week")
        case 3:
            return String(localized: "this month")
        case 4:
            return String(localized: "this year")
        default:
            return "this week"
        }
    }

    var timeLeft: String {
        let calendar = Calendar.current

        if budget.isFault {
            return ""
        }

        if budgetRows {
            if budget.type == 1 {
                let components = calendar.dateComponents([.hour], from: budget.wrappedDate, to: Date.now)

                return String(localized: "\(24 - components.hour!)h left")
            } else if budget.type == 2 {
                let components = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)

                return String(localized: "\(7 - (components.day ?? 0))d left")
            } else {
                let components1 = calendar.dateComponents([.day], from: budget.wrappedDate, to: budget.endDate)
                let numberOfDays = components1.day ?? 0

                let components2 = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
                let numberOfDaysPast = components2.day ?? 0

                let daysLeftNumber = Int(numberOfDays - numberOfDaysPast)
                return String(localized: "\(daysLeftNumber)d left"
                )
            }
        } else {
            if budget.type == 1 {
                let components = calendar.dateComponents([.hour], from: budget.wrappedDate, to: Date.now)

                return String(localized: "\(24 - (components.hour ?? 0)) hours left")
            } else if budget.type == 2 {
                let components = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)

                return String(localized: "\(7 - (components.day ?? 0)) days left")
            } else {
                let components1 = calendar.dateComponents([.day], from: budget.wrappedDate, to: budget.endDate)
                let numberOfDays = components1.day ?? 0

                let components2 = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
                let numberOfDaysPast = components2.day ?? 0

                let daysLeftNumber = Int(numberOfDays - numberOfDaysPast)
                return String(localized: "\(daysLeftNumber) days left")
            }
        }
    }

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var difference: Double {
        return abs(budgetAmount - totalSpent)
    }

    var percentString: String {
        if !budget.isFault {
            return "\(Int(round(100 - (totalSpent / budgetAmount) * 100)))%"
        } else {
            return ""
        }
    }

    var percentString1: String {
        if !budget.isFault {
            return "\(Int(round((totalSpent / budgetAmount) * 100)))%"
        } else {
            return ""
        }
    }

    var targetPercent: Double {
        let calendar = Calendar.current

        if budget.isFault {
            return 0.0
        }

        let components1 = calendar.dateComponents([.day], from: budget.wrappedDate, to: budget.endDate)
        let numberOfDays = components1.day ?? 0

        let components2 = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
        let numberOfDaysPast = components2.day ?? 0 + 1

        return Double(numberOfDays - numberOfDaysPast) / Double(numberOfDays)
    }

    @Environment(\.colorScheme) var colorScheme

    // swipe to delete
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @State private var offset: CGFloat = 0
    @State private var deleted: Bool = false

    var deletePopup: Bool {
        return abs(offset) > UIScreen.main.bounds.width * 0.15
    }

    var deleteConfirm: Bool {
        return abs(offset) > UIScreen.main.bounds.width * 0.50
    }

    @GestureState var isDragging = false

    var body: some View {
        Group {
            if budgetRows {
                ZStack(alignment: .trailing) {
                    Image(systemName: "xmark")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
//                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(deleteConfirm ? Color.AlertRed : Color.SubtitleText)
                        .padding(5)
                        .background(deleteConfirm ? Color.AlertRed.opacity(0.23) : Color.SecondaryBackground, in: Circle())
                        .scaleEffect(deleteConfirm ? 1.1 : 1)
                        .contentShape(Circle())
                        .opacity(deleted ? 0 : 1)
                        .padding(.horizontal, 10)
                        .offset(x: 80)
                        .offset(x: max(-80, offset))

                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.white)

                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(hex: budget.wrappedColour).opacity(0.3))
                            }
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(budget.wrappedEmoji)
                                    .font(.system(size: 20))
                            }

                            VStack(alignment: .leading, spacing: -0.5) {
                                Text(budget.wrappedName)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
//                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .foregroundColor(Color.PrimaryText)

                                Text("\(timeLeft) • \(percentString1) spent")
                                    .font(.system(.footnote, design: .rounded).weight(.medium))
//                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .lineLimit(1)
                                    .foregroundColor(Color.SubtitleText)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: -4) {
                            BudgetDollarView(amount: difference, red: totalSpent >= budgetAmount, scale: 1, size: 80)

                            Text("\(budgetAmount >= totalSpent ? "left" : "over") \(budgetType)")
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .foregroundColor(Color.SubtitleText)
                        }
                    }
                    .padding(10)
                    .background(colorScheme == .dark ? Color.Outline.opacity(0.2) : Color.Outline.opacity(0.35), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 13))
                    .contextMenu {
                        Button {
                            toEdit = budget

                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            toDelete = budget
                        } label: {
                            Label("Delete", systemImage: "xmark.bin")
                        }
                    }
                    .offset(x: offset)
                }
                .padding(.horizontal, 30)
                .onChange(of: deletePopup) { _ in
                    if deletePopup {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onChange(of: deleteConfirm) { _ in
                    if deleteConfirm {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
                }
                .animation(.default, value: deletePopup)
                .simultaneousGesture(
                    DragGesture()
                        .updating($isDragging, body: { _, state, _ in
                            state = true
                        })
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }.onEnded { _ in
                            if deleteConfirm {
                                deleted = true
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    offset -= UIScreen.main.bounds.width
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    withAnimation {
                                        moc.delete(budget)
                                        dataController.save()
                                    }
                                }

                            } else if deletePopup {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    offset = 0
                                }

                                toDelete = budget
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    offset = 0
                                }
                            }
                        }
                )
                .onChange(of: isDragging) { _ in
                    if !isDragging && !deleted {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = 0
                        }
                    }
                }
            } else {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 0.5) {
                            HStack(spacing: 4) {
                                Text(budget.wrappedEmoji)
                                    .font(.system(.caption, design: .rounded))
//                                    .font(.system(size: 11.5))

                                Text(budget.wrappedName)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
//                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .foregroundColor(Color.PrimaryText)
                            }

                            Text(timeLeft)
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
//                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.SubtitleText)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 30)

                    HStack {
                        VStack(alignment: .leading, spacing: -2) {
                            if totalSpent < budgetAmount {
                                Text("\(percentString1) SPENT")
                                    .font(.system(.caption2, design: .rounded).weight(.semibold))
//                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .foregroundColor(totalSpent / budgetAmount > 1 ? Color("BudgetRed") : Color.IncomeGreen)
                                    .padding(.bottom, 5)
                            }

                            BudgetDollarView(amount: difference, red: totalSpent >= budgetAmount, scale: 2, size: width - 40)

                            Text("\(budgetAmount >= totalSpent ? "left" : "over") \(budgetType)")
                                .font(.system(.footnote, design: .rounded).weight(.medium))
                                .foregroundColor(Color.SubtitleText)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                                .fill(Color.SecondaryBackground)
                                .frame(width: proxy.size.width)

                            if totalSpent / budgetAmount < 0.98 {
                                if let category = budget.category {
                                    AnimatedHorizontalBarGraphBudget(category: category)
                                        .frame(width: proxy.size.width * (1 - totalSpent / budgetAmount))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .topLeading) {
                            if budget.type != 1 && totalSpent < budgetAmount && targetPercent > 0 && targetPercent < 0.95 {
                                RoundedTriangle(cornerRadius: 1.3)
                                    .fill((targetPercent * budgetAmount) <= (budgetAmount - totalSpent) ? Color.DarkBackground : Color.BudgetRed)
                                    .frame(width: 14, height: 6.5)
                                    .offset(x: (targetPercent * proxy.size.width) - 7, y: -3.5)
                            }
                        }
                    }
                    .frame(height: 17.5)
                }
                .padding(15)
                .frame(width: width + 30)
                .background(colorScheme == .dark ? Color.Outline.opacity(0.2) : Color.Outline.opacity(0.35), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 13))
                .contextMenu {
                    Button {
                        toEdit = budget

                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        toDelete = budget
                    } label: {
                        Label("Delete", systemImage: "xmark.bin")
                    }
                }
            }
        }
        .onAppear {
            if budget.isFault {
                return
            }

            var holdingTotal = 0.0
            transactions.forEach { transaction in
                holdingTotal += transaction.wrappedAmount
            }

            totalSpent = holdingTotal
        }
    }

    init(budget: Budget, toDelete: Binding<Budget?>?, toEdit: Binding<Budget?>?, budgetRows: Bool) {
        self.budget = budget
        self.budgetRows = budgetRows
        _toDelete = toDelete ?? Binding.constant(nil)
        _toEdit = toEdit ?? Binding.constant(nil)

        let date = budget.startDate ?? Date.now

        let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), date as CVarArg)
        let endPredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)
        let incomePredicate = NSPredicate(format: "income = %d", false)

        let andPredicate: NSCompoundPredicate

        if let category = budget.category {
            let categoryPredicate = NSPredicate(format: "%K == %@", #keyPath(Transaction.category), category)
            andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, categoryPredicate, incomePredicate])

            _transactions = FetchRequest<Transaction>(sortDescriptors: [], predicate: andPredicate)
        } else {
            andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, incomePredicate])

            _transactions = FetchRequest<Transaction>(sortDescriptors: [], predicate: andPredicate)
        }
    }
}

struct AnimatedBudgetBarGraph: View {
    var color: Color
    var percent: Double

    @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated: Bool = true
    @State var showBar: Bool = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.opacity(0.3))
                    .frame(height: proxy.size.height)

                if percent > 0 {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(color.opacity(0.73))
                            .frame(height: showBar ? nil : 0, alignment: .bottom)
                    }
                    .frame(height: proxy.size.height * percent)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if !animated {
                    showBar = true
                } else {
                    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                        showBar = true
                    }
                }
            }
        }
    }
}

struct BudgetDollarView: View {
    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    var amount: Double
    var red: Bool
    var scale: Int
    var size: CGFloat

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var dynamicTypeSizes: (symbol: Font.TextStyle, amount: Font.TextStyle) {
        if scale == 1 {
            return (.callout, .title3)
        } else if scale == 2 {
            return (.body, .title2)
        } else {
            return (.title2, .largeTitle)
        }
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 1.3) {
            Group {
                Text(currencySymbol)
                    .font(.system(dynamicTypeSizes.symbol, design: .rounded).weight(.medium))
                    .foregroundColor(red ? Color("BudgetRed") : Color.SubtitleText) +

                Text("\(amount, specifier: showCents && amount < 100 ? "%.2f" : "%.0f")")
                    .font(.system(dynamicTypeSizes.amount, design: .rounded).weight(.medium))
                    .foregroundColor(red ? Color("BudgetRed") : Color.PrimaryText)
            }
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

struct DetailedBudgetDollarView: View {
    var amount: Double
    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 1.3) {
            Group {
                Text(currencySymbol)
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .foregroundColor(Color.SubtitleText) +

                Text("\(amount, specifier: showCents && amount < 100 ? "%.2f" : "%.0f")")
                    .font(.system(.largeTitle, design: .rounded).weight(.medium))
                    .foregroundColor(Color.PrimaryText)
            }
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

struct DetailedBudgetDifferenceDollarView: View {
    var amount: Double
    var red: Bool

    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 1.3) {
            Group {
                Text(currencySymbol)
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .foregroundColor(red ? Color("BudgetRed") : Color.SubtitleText) +

                Text("\(amount, specifier: showCents && amount < 100 ? "%.2f" : "%.0f")")
                    .font(.system(.largeTitle, design: .rounded).weight(.medium))
                    .foregroundColor(red ? Color("BudgetRed") : Color.PrimaryText)
            }
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

struct DeleteBudgetAlert: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    let toDelete: Budget
    @Environment(\.colorScheme) var systemColorScheme

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var bottomEdge: Double = 15

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }

            VStack(alignment: .leading, spacing: 1.5) {
                Text("Delete the '\(toDelete.category?.wrappedName ?? "")' budget?")
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .foregroundColor(.PrimaryText)

                Text("This action cannot be undone.")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundColor(.SubtitleText)
                    .padding(.bottom, 25)

                Button {
                    dismiss()
                    self.presentationMode.wrappedValue.dismiss()

                    withAnimation {
                        moc.delete(toDelete)
                        dataController.save()
                    }

                } label: {
                    DeleteButton(text: "Delete", red: true)
                }
                .padding(.bottom, 8)

                Button {
                    withAnimation(.easeOut(duration: 0.7)) {
                        dismiss()
                    }

                } label: {
                    DeleteButton(text: "Cancel", red: false)
                }
            }
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height < 0 {
                            offset = gesture.translation.height / 3
                        } else {
                            offset = gesture.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 20 {
                            dismiss()
                        } else {
                            withAnimation {
                                offset = 0
                            }
                        }
                    }
            )
            .padding(.horizontal, 17)
            .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
        }
        .edgesIgnoringSafeArea(.all)
        .background(BackgroundBlurView())
    }
}

struct DeleteMainBudgetAlert: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let toDelete: MainBudget
    @Environment(\.colorScheme) var systemColorScheme

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var bottomEdge: Double = 15

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }

            VStack(alignment: .leading, spacing: 1.5) {
                Text("Delete your overall budget?")
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .foregroundColor(.PrimaryText)

                Text("This action cannot be undone.")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundColor(.SubtitleText)
                    .padding(.bottom, 25)

                Button {
                    dismiss()

                    withAnimation {
                        moc.delete(toDelete)
                        dataController.save()
                    }

                } label: {
                    DeleteButton(text: "Delete", red: true)
                }
                .padding(.bottom, 8)

                Button {
                    withAnimation(.easeOut(duration: 0.7)) {
                        dismiss()
                    }

                } label: {
                    DeleteButton(text: "Cancel", red: false)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height < 0 {
                            offset = gesture.translation.height / 3
                        } else {
                            offset = gesture.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 20 {
                            dismiss()
                        } else {
                            withAnimation {
                                offset = 0
                            }
                        }
                    }
            )
            .padding(.horizontal, 17)
            .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
        }
        .edgesIgnoringSafeArea(.all)
        .background(BackgroundBlurView())
    }
}

struct DetailedBudgetView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    let budget: Budget

    @State private var toDelete: Budget?

    @State var newTransaction = false

    @State private var toEdit: Budget?

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Button {
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.SubtitleText)

                        Text("Back")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.SubtitleText)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                    .background(Color.SecondaryBackground, in: Capsule())
                }

                Spacer()

                DetailedBudgetViewTopBarButton(imageName: "plus", color: Color("110")) {
                    newTransaction = true
                }

                DetailedBudgetViewTopBarButton(imageName: "pencil", color: Color("6")) {
                    toEdit = budget
                }

                DetailedBudgetViewTopBarButton(imageName: "trash.fill", color: Color.AlertRed) {
                    toDelete = budget
                }
            }
            .padding(.horizontal, 20)

            TimeBudgetView(budget: budget)
        }
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.PrimaryBackground)
        .sheet(item: $toEdit, onDismiss: {
            toEdit = nil
        }) { budget in
            BrandNewBudgetView(overallBudgetCreated: false, toEditBudget: budget)
        }
        .fullScreenCover(isPresented: $newTransaction) {
            TransactionView(category: budget.category)
        }
        .fullScreenCover(item: $toDelete, onDismiss: {
            toDelete = nil
        }) { budget in
            DeleteBudgetAlert(toDelete: budget)
        }
    }
}

struct DetailedMainBudgetView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    let budget: MainBudget

    @State private var toDelete: MainBudget?

    @State private var toEdit: MainBudget?

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Button {
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.SubtitleText)

                        Text("Back")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.SubtitleText)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
//                    .frame(height: 30, alignment: .center)
                    .background(Color.SecondaryBackground, in: Capsule())
                }

                Spacer()

                DetailedBudgetViewTopBarButton(imageName: "pencil", color: Color("6")) {
                    toEdit = budget
                }

                DetailedBudgetViewTopBarButton(imageName: "trash.fill", color: Color.AlertRed) {
                    toDelete = budget
                }
            }
            .padding(.horizontal, 20)

            TimeMainBudgetView(budget: budget)
        }
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.PrimaryBackground)
        .fullScreenCover(item: $toEdit, onDismiss: {
            toEdit = nil
        }) { budget in
            BrandNewBudgetView(overallBudgetCreated: true, toEditMainBudget: budget)
        }
        .fullScreenCover(item: $toDelete, onDismiss: {
            toDelete = nil
        }) { budget in
            DeleteMainBudgetAlert(toDelete: budget)
        }
    }
}

struct TimeBudgetView: View {
    let budget: Budget

    var budgetAmount: Double {
        return budget.amount
    }

    var budgetType: Int {
        return Int(budget.type)
    }

    @State var startDate = Date.now

    var dateString: String {
        let dateFormatter = DateFormatter()

        if budgetType == 1 {
            dateFormatter.dateFormat = "d MMM yyyy"
            return dateFormatter.string(from: startDate)
        } else if budgetType == 2 {
            let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? Date.now
            dateFormatter.dateFormat = "d MMM"
            return dateFormatter.string(from: startDate) + " - " + dateFormatter.string(from: endDate)
        } else if budgetType == 3 {
            var endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
            endDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
            dateFormatter.dateFormat = "d MMM"
            return dateFormatter.string(from: startDate) + " - " + dateFormatter.string(from: endDate)
        } else if budgetType == 4 {
            var endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
            endDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
            dateFormatter.dateFormat = "d MMM yy"
            return dateFormatter.string(from: startDate) + " - " + dateFormatter.string(from: endDate)
        } else {
            return ""
        }
    }

    @State var totalSpent = 0.0

    var timeLeft: String {
        let calendar = Calendar.current

        if budgetType == 1 {
            let components = calendar.dateComponents([.hour], from: budget.wrappedDate, to: Date.now)
            return String(localized: "\(24 - (components.hour ?? 0)) hours left")
        } else {
            return String(localized: "\(daysLeftNumber) days left")
        }
    }

    var subtitleText: String {
        if budget.startDate == startDate {
            return timeLeft
        } else {
            return dateString
        }
    }

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var difference: Double {
        abs(budgetAmount - totalSpent)
    }

    var differenceSubtitle: String {
        if budgetAmount >= totalSpent {
            if startDate == budget.startDate {
                if budgetType == 1 {
                    return String(localized: "left today")
                } else if budgetType == 2 {
                    return String(localized: "left this week")
                } else if budgetType == 3 {
                    return String(localized: "left this month")
                } else if budgetType == 4 {
                    return String(localized: "left this year")
                } else {
                    return ""
                }
            } else {
                if budgetType == 1 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d MMM"
                    return String(localized: "left on \(dateFormatter.string(from: startDate))")
                } else if budgetType == 2 {
                    let components = Calendar.current.dateComponents([.day], from: startDate, to: budget.wrappedDate)
                    let weekString = String(localized: "\((components.day ?? 0) / 7) weeks ago")
                    return String(localized: "left \(weekString)")
                } else if budgetType == 3 {
                    let components = Calendar.current.dateComponents([.month], from: startDate, to: budget.wrappedDate)
                    let monthString = String(localized: "\(components.month!) months ago")
                    return String(localized: "left \(monthString)")
                } else if budgetType == 4 {
                    let components = Calendar.current.dateComponents([.year], from: startDate, to: budget.wrappedDate)
                    let yearString = String(localized: "\(components.year!) months ago")
                    return String(localized: "left \(yearString)")
                } else {
                    return ""
                }
            }
        } else {
            if startDate == budget.startDate {
                if budgetType == 1 {
                    return String(localized: "over today")
                } else if budgetType == 2 {
                    return String(localized: "over this week")
                } else if budgetType == 3 {
                    return String(localized: "over this month")
                } else if budgetType == 4 {
                    return String(localized: "over this year")
                } else {
                    return ""
                }
            } else {
                if budgetType == 1 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d MMM"
                    return String(localized: "over on \(dateFormatter.string(from: startDate))")
                } else if budgetType == 2 {
                    let components = Calendar.current.dateComponents([.day], from: startDate, to: budget.wrappedDate)
                    let weekString = String(localized: "\((components.day ?? 0) / 7) weeks ago")
                    return String(localized: "over \(weekString)")
                } else if budgetType == 3 {
                    let components = Calendar.current.dateComponents([.month], from: startDate, to: budget.wrappedDate)
                    let monthString = String(localized: "\(components.month!) months ago")
                    return String(localized: "over \(monthString)")
                } else if budgetType == 4 {
                    let components = Calendar.current.dateComponents([.year], from: startDate, to: budget.wrappedDate)
                    let yearString = String(localized: "\(components.year!) months ago")
                    return String(localized: "over \(yearString)")
                } else {
                    return ""
                }
            }
        }
    }

    // for week, month, year only

    var daysLeftNumber: Int {
        let calendar = Calendar.current

        if budgetType == 1 {
            return 0
        } else if budgetType == 2 {
            let components = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
            return 7 - (components.day ?? 0)
        } else if budgetType == 3 {
            let components1 = calendar.dateComponents([.day], from: budget.wrappedDate, to: budget.endDate)
            let numberOfDays = components1.day!
            let components2 = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
            let numberOfDaysPast = components2.day!

            return Int(numberOfDays - numberOfDaysPast)
        } else if budgetType == 4 {
            let components1 = calendar.dateComponents([.day], from: budget.wrappedDate, to: budget.endDate)
            let numberOfDays = components1.day!
            let components2 = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
            let numberOfDaysPast = components2.day!
            return Int(numberOfDays - numberOfDaysPast)
        } else {
            return 0
        }
    }

    var leftPerDay: Double {
        if budgetType >= 2 {
            return (budgetAmount - totalSpent) / Double(daysLeftNumber)
        } else {
            return 0
        }
    }

    var showExtraDetails: Bool {
        if budgetType >= 2 {
            return budget.startDate == startDate && totalSpent < budgetAmount && daysLeftNumber != 1
        } else {
            return false
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // budget name and emoji and time left
            VStack(spacing: 10) {
                HStack(spacing: 7.5) {
                    Text(budget.wrappedEmoji)
                        .font(.system(.subheadline, design: .rounded))
                    Text(budget.wrappedName)
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .lineLimit(1)
                }
                .foregroundColor(Color.PrimaryText)

                Text(subtitleText)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(Color.SubtitleText)
                    .padding(4)
                    .padding(.horizontal, 7)
                    .background(Color.SecondaryBackground, in: Capsule())
            }
            .padding(.bottom, 15)

            // amount left and averages

            if budgetType >= 2 {
                HStack(alignment: .top, spacing: 15) {
                    VStack(alignment: showExtraDetails ? .leading : .center, spacing: -4) {
                        DetailedBudgetDifferenceDollarView(amount: difference, red: totalSpent >= budgetAmount)

                        Text(differenceSubtitle)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(Color.SubtitleText)
                    }
                    .frame(maxWidth: .infinity, alignment: showExtraDetails ? .leading : .center)

                    if showExtraDetails {
                        VStack(alignment: .trailing, spacing: -4) {
                            DetailedBudgetDollarView(amount: leftPerDay)

                            Text("left each day")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
//                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color.SubtitleText)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 25)
            } else {
                VStack(spacing: -4) {
                    DetailedBudgetDifferenceDollarView(amount: difference, red: totalSpent >= budgetAmount)

                    Text(differenceSubtitle)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
//                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                }
                .padding(.horizontal, 25)
            }

            // bar graph

            VStack(spacing: 5) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                            .fill(Color.SecondaryBackground)
                            .frame(width: proxy.size.width)

                        if totalSpent / budgetAmount < 0.98 {
                            if let category = budget.category {
                                AnimatedHorizontalBarGraphBudget(category: category)
                                    .frame(width: proxy.size.width * (1 - totalSpent / budgetAmount))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 28)

                HStack {
                    Text("\(currencySymbol)\(totalSpent, specifier: "%.2f")")
                    Spacer()
                    Text("\(currencySymbol)\(budgetAmount, specifier: "%.2f")")
                }
                .frame(maxWidth: .infinity)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color.SubtitleText)
            }
            .padding(.bottom, budgetType >= 2 ? 20 : 0)
            .padding(.horizontal, 25)

            if budgetType == 1 {
                Divider()
                    .overlay(Color.Outline)
                    .padding(.horizontal, 25)
            }

            if let category = budget.category {
                ScrollView(showsIndicators: false) {
                    if budgetType == 1 {
                        FilteredCategoryDayBudgetView(category: category, day: startDate, totalSpent: $totalSpent)
                            .padding(.horizontal, 15)
                    } else {
                        FilteredBudgetView(category: category, startDate: startDate, totalSpent: $totalSpent, type: budgetType - 1)
                            .padding(.horizontal, 15)
                    }
                }
                .frame(maxHeight: .infinity)

                BudgetStepperView(category: category, date: $startDate, startDate: budget.wrappedDate, budgetType: budgetType)
                    .padding(.horizontal, 25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            startDate = budget.wrappedDate
        }
    }
}

struct FilteredCategoryDayBudgetView: View {
    @FetchRequest private var transactions: FetchedResults<Transaction>
    @Binding var totalSpent: Double
    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var date: Date

    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @AppStorage("showCents", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showCents: Bool = true
    @AppStorage("swapTimeLabel", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var swapTimeLabel: Bool = false
    @AppStorage("showExpenseOrIncomeSign", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
    var showExpenseOrIncomeSign: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            if transactions.count == 0 {
                NoResultsView(fullscreen: false)
            } else {
                ForEach(transactions, id: \.id) { transaction in
                    SingleTransactionView(transaction: transaction, showCents: showCents, currencySymbol: currencySymbol, currency: currency, swapTimeLabel: swapTimeLabel, future: false, showExpenseOrIncomeSign: showExpenseOrIncomeSign)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                var holding = 0.0
                transactions.forEach { transaction in

                    holding += transaction.wrappedAmount
                }

                totalSpent = holding
            }
        }
        .onChange(of: date) { _ in
            DispatchQueue.main.async {
                var holding = 0.0
                transactions.forEach { transaction in

                    holding += transaction.wrappedAmount
                }

                totalSpent = holding
            }
        }
//        .fullScreenCover(item: $toDelete, onDismiss: {
//            toDelete = nil
//        }) { transaction in
//            DeleteTransactionAlert(toDelete: transaction, stopRecurring: false)
//        }
//        .fullScreenCover(item: $toEdit, onDismiss: {
//            toEdit = nil
//        }) { transaction in
//            TransactionView(toEdit: transaction)
//        }
        .frame(maxHeight: .infinity)
    }

    init(category: Category?, day: Date, totalSpent: Binding<Double>) {
        date = day

        let datePredicate = NSPredicate(format: "%K == %@", #keyPath(Transaction.day), day as CVarArg)
        let dateCapPredicate = NSPredicate(format: "%K <= %@", #keyPath(Transaction.date), Date.now as CVarArg)
        let incomePredicate = NSPredicate(format: "income = %d", false)

        if let unwrappedCategory = category {
            let categoryPredicate = NSPredicate(format: "%K == %@", #keyPath(Transaction.category), unwrappedCategory)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [datePredicate, categoryPredicate, incomePredicate, dateCapPredicate])

            _transactions = FetchRequest<Transaction>(sortDescriptors: [
                SortDescriptor(\.date, order: .reverse)
            ], predicate: andPredicate)
        } else {
            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [datePredicate, incomePredicate, dateCapPredicate])

            _transactions = FetchRequest<Transaction>(sortDescriptors: [
                SortDescriptor(\.date, order: .reverse)
            ], predicate: andPredicate)
        }

        _totalSpent = totalSpent
    }
}

struct FilteredBudgetView: View {
    @SectionedFetchRequest<Date?, Transaction> private var transactions: SectionedFetchResults<Date?, Transaction>

    @Binding var totalSpent: Double
    var date: Date

    var body: some View {
        VStack(spacing: 30) {
            if transactions.count == 0 {
                NoResultsView(fullscreen: false)
            }

            ListView(transactions: _transactions)
        }
        .frame(maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.async {
                var holding = 0.0
                transactions.forEach { day in

                    day.forEach { transaction in
                        holding += transaction.wrappedAmount
                    }
                }

                totalSpent = holding
            }
        }
        .onChange(of: date) { _ in
            DispatchQueue.main.async {
                var holding = 0.0
                transactions.forEach { day in

                    day.forEach { transaction in
                        holding += transaction.wrappedAmount
                    }
                }
                totalSpent = holding
            }
        }
    }

    init(category: Category? = nil, startDate: Date, totalSpent: Binding<Double>, type: Int) {
        date = startDate

        let startPredicate = NSPredicate(format: "%K >= %@", #keyPath(Transaction.date), startDate as CVarArg)
        let incomePredicate = NSPredicate(format: "income = %d", false)
        let endPredicate: NSPredicate

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.com.rafaelsoh.dime")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        if type == 1 {
            if calendar.isDate(startDate, equalTo: Date.now, toGranularity: .weekOfYear) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .day, value: 7, to: startDate) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        } else if type == 2 {
            if calendar.isDate(startDate, equalTo: Date.now, toGranularity: .month) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .month, value: 1, to: startDate) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        } else {
            if calendar.isDate(startDate, equalTo: Date.now, toGranularity: .year) {
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
            } else {
                let next = calendar.date(byAdding: .year, value: 1, to: startDate) ?? Date.now
                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
            }
        }

        if let unwrappedCategory = category {
            let categoryPredicate = NSPredicate(format: "%K == %@", #keyPath(Transaction.category), unwrappedCategory)

            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, categoryPredicate, incomePredicate])

            _transactions = SectionedFetchRequest<Date?, Transaction>(sectionIdentifier: \.day, sortDescriptors: [
                SortDescriptor(\.day, order: .reverse),
                SortDescriptor(\.date, order: .reverse)
            ], predicate: andPredicate)
        } else {
            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [startPredicate, endPredicate, incomePredicate])

            _transactions = SectionedFetchRequest<Date?, Transaction>(sectionIdentifier: \.day, sortDescriptors: [
                SortDescriptor(\.day, order: .reverse),
                SortDescriptor(\.date, order: .reverse)
            ], predicate: andPredicate)
        }

        _totalSpent = totalSpent
    }
}

struct TimeMainBudgetView: View {
    let budget: MainBudget

    var budgetAmount: Double {
        return budget.amount
    }

    var budgetType: Int {
        return Int(budget.type)
    }

    @State var startDate = Date.now

    var dateString: String {
        let dateFormatter = DateFormatter()

        if budgetType == 1 {
            dateFormatter.dateFormat = "d MMM yyyy"
            return dateFormatter.string(from: startDate)
        } else if budgetType == 2 {
            let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? Date.now
            dateFormatter.dateFormat = "d MMM"
            return dateFormatter.string(from: startDate) + " - " + dateFormatter.string(from: endDate)
        } else if budgetType == 3 {
            var endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
            endDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
            dateFormatter.dateFormat = "d MMM"
            return dateFormatter.string(from: startDate) + " - " + dateFormatter.string(from: endDate)
        } else if budgetType == 4 {
            var endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
            endDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
            dateFormatter.dateFormat = "d MMM yy"
            return dateFormatter.string(from: startDate) + " - " + dateFormatter.string(from: endDate)
        } else {
            return ""
        }
    }

    @State var totalSpent = 0.0

    var timeLeft: String {
        let calendar = Calendar.current

        if budgetType == 1 {
            let components = calendar.dateComponents([.hour], from: budget.wrappedDate, to: Date.now)
            return String(localized: "\(24 - (components.hour ?? 0)) hours left")
        } else {
            return String(localized: "\(daysLeftNumber) days left")
        }
    }

    var subtitleText: String {
        if budget.startDate == startDate {
            return timeLeft
        } else {
            return dateString
        }
    }

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    var difference: Double {
        abs(budgetAmount - totalSpent)
    }

    var differenceSubtitle: String {
        if budgetAmount >= totalSpent {
            if startDate == budget.startDate {
                if budgetType == 1 {
                    return String(localized: "left today")
                } else if budgetType == 2 {
                    return String(localized: "left this week")
                } else if budgetType == 3 {
                    return String(localized: "left this month")
                } else if budgetType == 4 {
                    return String(localized: "left this year")
                } else {
                    return ""
                }
            } else {
                if budgetType == 1 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d MMM"
                    return String(localized: "left on \(dateFormatter.string(from: startDate))")
                } else if budgetType == 2 {
                    let components = Calendar.current.dateComponents([.day], from: startDate, to: budget.wrappedDate)
                    let weekString = String(localized: "\((components.day ?? 0) / 7) weeks ago")
                    return String(localized: "left \(weekString)")
                } else if budgetType == 3 {
                    let components = Calendar.current.dateComponents([.month], from: startDate, to: budget.wrappedDate)
                    let monthString = String(localized: "\(components.month!) months ago")
                    return String(localized: "left \(monthString)")
                } else if budgetType == 4 {
                    let components = Calendar.current.dateComponents([.year], from: startDate, to: budget.wrappedDate)
                    let yearString = String(localized: "\(components.year!) months ago")
                    return String(localized: "left \(yearString)")
                } else {
                    return ""
                }
            }
        } else {
            if startDate == budget.startDate {
                if budgetType == 1 {
                    return String(localized: "over today")
                } else if budgetType == 2 {
                    return String(localized: "over this week")
                } else if budgetType == 3 {
                    return String(localized: "over this month")
                } else if budgetType == 4 {
                    return String(localized: "over this year")
                } else {
                    return ""
                }
            } else {
                if budgetType == 1 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d MMM"
                    return String(localized: "over on \(dateFormatter.string(from: startDate))")
                } else if budgetType == 2 {
                    let components = Calendar.current.dateComponents([.day], from: startDate, to: budget.wrappedDate)
                    let weekString = String(localized: "\((components.day ?? 0) / 7) weeks ago")
                    return String(localized: "over \(weekString)")
                } else if budgetType == 3 {
                    let components = Calendar.current.dateComponents([.month], from: startDate, to: budget.wrappedDate)
                    let monthString = String(localized: "\(components.month!) months ago")
                    return String(localized: "over \(monthString)")
                } else if budgetType == 4 {
                    let components = Calendar.current.dateComponents([.year], from: startDate, to: budget.wrappedDate)
                    let yearString = String(localized: "\(components.year!) months ago")
                    return String(localized: "over \(yearString)")
                } else {
                    return ""
                }
            }
        }
    }

    // for week, month, year only

    var daysLeftNumber: Int {
        let calendar = Calendar.current

        if budgetType == 1 {
            return 0
        } else if budgetType == 2 {
            let components = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
            return 7 - (components.day ?? 0)
        } else if budgetType == 3 {
            let components1 = calendar.dateComponents([.day], from: budget.wrappedDate, to: budget.endDate)
            let numberOfDays = components1.day!
            let components2 = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
            let numberOfDaysPast = components2.day!

            return Int(numberOfDays - numberOfDaysPast)
        } else if budgetType == 4 {
            let components1 = calendar.dateComponents([.day], from: budget.wrappedDate, to: budget.endDate)
            let numberOfDays = components1.day!
            let components2 = calendar.dateComponents([.day], from: budget.wrappedDate, to: Date.now)
            let numberOfDaysPast = components2.day!
            return Int(numberOfDays - numberOfDaysPast)
        } else {
            return 0
        }
    }

    var leftPerDay: Double {
        if budgetType >= 2 {
            return (budgetAmount - totalSpent) / Double(daysLeftNumber)
        } else {
            return 0
        }
    }

    var showExtraDetails: Bool {
        if budgetType >= 2 {
            return budget.startDate == startDate && totalSpent < budgetAmount && daysLeftNumber != 1
        } else {
            return false
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // budget name and emoji and time left
            VStack(spacing: 10) {
                Text("Overall Budget")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .lineLimit(1)
                    .foregroundColor(Color.PrimaryText)

                Text(subtitleText)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(Color.SubtitleText)
                    .padding(4)
                    .padding(.horizontal, 7)
                    .background(Color.SecondaryBackground, in: Capsule())
            }
            .padding(.bottom, 15)

            // amount left and averages

            if budgetType >= 2 {
                HStack(alignment: .top, spacing: 15) {
                    VStack(alignment: showExtraDetails ? .leading : .center, spacing: -4) {
                        DetailedBudgetDifferenceDollarView(amount: difference, red: totalSpent >= budgetAmount)

                        Text(differenceSubtitle)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(Color.SubtitleText)
                    }
                    .frame(maxWidth: .infinity, alignment: showExtraDetails ? .leading : .center)

                    if showExtraDetails {
                        VStack(alignment: .trailing, spacing: -4) {
                            DetailedBudgetDollarView(amount: leftPerDay)

                            Text("left each day")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundColor(Color.SubtitleText)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 25)
            } else {
                VStack(spacing: -4) {
                    DetailedBudgetDifferenceDollarView(amount: difference, red: totalSpent >= budgetAmount)

                    Text(differenceSubtitle)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(Color.SubtitleText)
                }
                .padding(.horizontal, 25)
            }

            // bar graph

            VStack(spacing: 5) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                            .fill(Color.SecondaryBackground)
                            .frame(width: proxy.size.width)

                        if totalSpent / budgetAmount < 0.98 {
                            AnimatedHorizontalBarGraphMainBudget()
                                .frame(width: proxy.size.width * (1 - totalSpent / budgetAmount))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 28)

                HStack {
                    Text("\(currencySymbol)\(totalSpent, specifier: "%.2f")")
                    Spacer()
                    Text("\(currencySymbol)\(budgetAmount, specifier: "%.2f")")
                }
                .frame(maxWidth: .infinity)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color.SubtitleText)
            }
            .padding(.bottom, budgetType >= 2 ? 20 : 0)
            .padding(.horizontal, 25)

            if budgetType == 1 {
                Divider()
                    .overlay(Color.Outline)
                    .padding(.horizontal, 25)
            }

            ScrollView(showsIndicators: false) {
                if budgetType == 1 {
                    FilteredCategoryDayBudgetView(category: nil, day: startDate, totalSpent: $totalSpent)
                        .padding(.horizontal, 15)
                } else {
                    FilteredBudgetView(category: nil, startDate: startDate, totalSpent: $totalSpent, type: budgetType - 1)
                        .padding(.horizontal, 15)
                }
            }
            .frame(maxHeight: .infinity)

            BudgetStepperView(category: nil, date: $startDate, startDate: budget.wrappedDate, budgetType: budgetType)
                .padding(.horizontal, 25)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            startDate = budget.wrappedDate
        }
    }
}

struct AnimatedHorizontalBarGraphBudget: View {
    let category: Category

    @State var showBar: Bool = false
    @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                .foregroundColor(Color(hex: category.wrappedColour))
                .frame(width: showBar ? nil : 0, alignment: .leading)

            Spacer(minLength: 0)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if !animated {
                    showBar = true
                } else {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        showBar = true
                    }
                }
            }
        }
    }
}

struct AnimatedHorizontalBarGraphMainBudget: View {
    @State var showBar: Bool = false
    @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                .fill(Color.DarkBackground)
                .frame(width: showBar ? nil : 0, alignment: .leading)

            Spacer(minLength: 0)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if !animated {
                    showBar = true
                } else {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        showBar = true
                    }
                }
            }
        }
    }
}

struct AnimatedCurvedBarGraphBudget: View {
    var transactions: FetchedResults<Transaction>
    var budgetTotal: Double
    let cornerRadius: Double
    let width: Double
    let color: String
    @State var percent: Double = 0

    @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated: Bool = true

    var body: some View {
        DonutSemicircle(percent: percent, cornerRadius: cornerRadius, width: width)
            .fill(Color(color))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    var holdingTotal = 0.0
                    transactions.forEach { transaction in
                        holdingTotal += transaction.wrappedAmount
                    }

                    if !animated {
                        percent = 1 - (holdingTotal / budgetTotal)
                    } else {
                        withAnimation(.easeInOut(duration: 0.7)) {
                            percent = 1 - (holdingTotal / budgetTotal)
                        }
                    }
                }
            }
    }
}

struct AnimatedCurvedBarGraphMainBudget: View {
    var transactions: FetchedResults<Transaction>
    var budgetTotal: Double
    let cornerRadius: Double
    let width: Double

    @State var percent: Double = 0

    @AppStorage("animated", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var animated: Bool = true

    var body: some View {
        DonutSemicircle(percent: percent, cornerRadius: cornerRadius, width: width)
            .fill(Color.DarkBackground)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    var holdingTotal = 0.0
                    transactions.forEach { transaction in
                        holdingTotal += transaction.wrappedAmount
                    }

                    if !animated {
                        percent = 1 - (holdingTotal / budgetTotal)
                    } else {
                        withAnimation(.easeInOut(duration: 0.7)) {
                            percent = 1 - (holdingTotal / budgetTotal)
                        }
                    }
                }
            }
    }
}

struct BudgetStepperView: View {
    @FetchRequest private var transactions: FetchedResults<Transaction>

    @Binding var date: Date
    var firstDate: Date {
        if transactions.isEmpty {
            return Date.now
        } else {
            return transactions[0].day ?? Date.now
        }
    }

    var endDate: Date {
        if type == 1 {
            return Calendar.current.date(byAdding: .day, value: 1, to: date)!
        } else if type == 2 {
            return Calendar.current.date(byAdding: .day, value: 6, to: date)!
        } else if type == 3 {
            let holdingDate = Calendar.current.date(byAdding: .month, value: 1, to: date)!
            return Calendar.current.date(byAdding: .day, value: -1, to: holdingDate)!
        } else if type == 4 {
            let holdingDate = Calendar.current.date(byAdding: .year, value: 1, to: date)!
            return Calendar.current.date(byAdding: .day, value: -1, to: holdingDate)!
        }

        return startDate
    }

    let startDate: Date
    let type: Int

    var dateString: String {
        let dateFormatter = DateFormatter()

        if type == 1 {
            dateFormatter.dateFormat = "d MMM yyyy"
            return dateFormatter.string(from: date)
        } else if type == 4 {
            dateFormatter.dateFormat = "d MMM yy"
            return dateFormatter.string(from: date) + " - " + dateFormatter.string(from: endDate)
        } else {
            dateFormatter.dateFormat = "d MMM"
            return dateFormatter.string(from: date) + " - " + dateFormatter.string(from: endDate)
        }
    }

    var body: some View {
        HStack {
            StepperButtonView(left: true, disabled: date <= firstDate) {
                if date > firstDate {
                    if type == 1 {
                        date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                    } else if type == 2 {
                        date = Calendar.current.date(byAdding: .day, value: -7, to: date)!
                    } else if type == 3 {
                        date = Calendar.current.date(byAdding: .month, value: -1, to: date)!
                    } else if type == 4 {
                        date = Calendar.current.date(byAdding: .year, value: -1, to: date)!
                    }
                }
            }

            Spacer()

            Text(dateString)
                .font(.system(.title3, design: .rounded).weight(.bold))

            Spacer()

            StepperButtonView(left: false, disabled: date == startDate) {
                if date < startDate {
                    if type == 1 {
                        date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                    } else if type == 2 {
                        date = Calendar.current.date(byAdding: .day, value: 7, to: date)!
                    } else if type == 3 {
                        date = Calendar.current.date(byAdding: .month, value: 1, to: date)!
                    } else if type == 4 {
                        date = Calendar.current.date(byAdding: .year, value: -1, to: date)!
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    init(category: Category?, date: Binding<Date>, startDate: Date, budgetType: Int) {
        if let unwrappedCategory = category {
            _transactions = FetchRequest<Transaction>(sortDescriptors: [
                SortDescriptor(\.day)
            ], predicate: NSPredicate(format: "%K == %@", #keyPath(Transaction.category), unwrappedCategory))
        } else {
            _transactions = FetchRequest<Transaction>(sortDescriptors: [
                SortDescriptor(\.day)
            ])
        }

        _date = date

        self.startDate = startDate
        type = budgetType
    }
}
