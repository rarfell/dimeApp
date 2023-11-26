//
//  CategoryView.swift
//  xpenz
//
//  Created by Rafael Soh on 10/5/22.
//

import Combine
import CoreHaptics
import Popovers
import SwiftUI
import UIKit

enum CategoryViewMode {
    case welcome, settings, transaction
}

struct CategoryView: View {
    var mode: CategoryViewMode
//    @Environment(\.colorScheme) var colorScheme
    @State var income = false
    @Namespace var animation

    @State var newCategory = false

    @FetchRequest(sortDescriptors: [SortDescriptor(\.order)], predicate: NSPredicate(format: "income = %d", false)) private var expenseCategories: FetchedResults<Category>

    @State var showToast = false
    @State var toastTitle = ""
    @State var toastImage = ""
    @State var positive = false

    var disabled: Bool {
        income == false && expenseCategories.count >= 24
    }

    var body: some View {
        VStack(spacing: 5) {
            CategoryListView(income: $income, mode: mode, showToast: $showToast, toastTitle: $toastTitle, toastImage: $toastImage, positive: $positive)

            HStack {
                HStack(spacing: 0) {
                    Text("Expense")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(income == false ? Color.PrimaryText : Color.SubtitleText)
                        .padding(6)
                        .padding(.horizontal, 8)
                        .background {
                            if income == false {
                                Capsule()
                                    .fill(Color.SecondaryBackground)
                                    .matchedGeometryEffect(id: "TAB1", in: animation)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            DispatchQueue.main.async {
                                withAnimation(.easeIn(duration: 0.15)) {
                                    income = false
                                }
                            }
                        }

                    Text("Income")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(income == true ? Color.PrimaryText : Color.SubtitleText)
                        .padding(6)
                        .padding(.horizontal, 8)
                        .background {
                            if income == true {
                                Capsule()
                                    .fill(Color.SecondaryBackground)
                                    .matchedGeometryEffect(id: "TAB1", in: animation)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            DispatchQueue.main.async {
                                withAnimation(.easeIn(duration: 0.15)) {
                                    income = true
                                }
                            }
                        }
                }
                .padding(3)
                .layoutPriority(1)
                .overlay(Capsule().stroke(Color.Outline.opacity(0.4), lineWidth: 1.3))

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "plus")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 14.5, weight: .semibold, design: .rounded))

                    Text("New")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundColor(Color.PrimaryText)
                .padding(6)
                .padding(.horizontal, 4.5)
                .background(Color.SecondaryBackground, in: Capsule())
                .opacity(disabled ? 0.5 : 1)
                .contentShape(Rectangle())
                .onTapGesture {
                    if disabled {
                        showToast = true
                        toastImage = "exclamationmark.triangle.fill"
                        toastTitle = "Limit Exceeded"
                        positive = false
                    } else {
                        newCategory = true
                    }
                }
            }
            .padding(25)
        }
        .sheet(isPresented: $newCategory) {
            if #available(iOS 16.0, *) {
                NewCategoryAlert(income: $income, bottomSpacers: false)
                    .presentationDetents([.height(270)])
            } else {
                NewCategoryAlert(income: $income, bottomSpacers: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.keyboard, edges: .all)
        .background(Color.PrimaryBackground)
    }
}

struct CategoryListView: View {
    @Binding var income: Bool
    var mode: CategoryViewMode

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @Environment(\.colorScheme) var systemColorScheme
    @EnvironmentObject var dataController: DataController

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var bottomEdge: Double = 15

    @AppStorage("categorySuggestions", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var showSuggestions: Bool = true
    @State var suggestionsToast = false

    @State private var offset: CGFloat = 0

    @FetchRequest private var categories: FetchedResults<Category>

    @State var isEditing = false

    @FetchRequest(sortDescriptors: [SortDescriptor(\.order)]) private var allCategories: FetchedResults<Category>

    // delete mode
    @State private var deleteMode = false
    @State private var toDelete: Category?
    var alertMessage: String {
        "Delete '" + (toDelete?.wrappedName ?? "") + "'?"
    }

    // edit mode
    @State private var toEdit: Category?

    // toasts
    @Binding var showToast: Bool
    @Binding var toastTitle: String
    @Binding var toastImage: String
    @Binding var positive: Bool

    var toastColor: Color {
        positive ? Color.IncomeGreen : Color.AlertRed
    }

    var sectionHeader: LocalizedStringKey {
        if income {
            return "INCOME CATEGORIES"
        } else {
            return "EXPENSE CATEGORIES"
        }
    }

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        VStack(spacing: 5) {
            if showToast {
                HStack(spacing: 6.5) {
                    Image(systemName: toastImage)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(toastColor)

                    Text(toastTitle)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .lineLimit(1)
//                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(toastColor)
                }
                .padding(8)
                .background(toastColor.opacity(0.23), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .transition(AnyTransition.opacity.combined(with: .move(edge: .top)))
                .frame(maxWidth: 250)
                .frame(height: 35)
                .padding(20)
            } else {
                if mode == .welcome {
                    HStack(spacing: 8) {
                        if categories.count > 1 {
                            if isEditing {
                                Circle()
                                    .fill(Color.IncomeGreen.opacity(0.23))
                                    .frame(width: 33, height: 33)
                                    .overlay {
                                        Image(systemName: "checkmark")
                                            .font(.system(.callout, design: .rounded).weight(.semibold))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.IncomeGreen)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }
                            } else {
                                Circle()
                                    .fill(Color.SecondaryBackground)
                                    .frame(width: 33, height: 33)
                                    .overlay {
                                        Image(systemName: "arrow.up.arrow.down")
                                            .font(.system(.callout, design: .rounded).weight(.semibold))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                            .foregroundColor(Color.SubtitleText)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }
                            }
                        }

                        Circle()
                            .fill(Color.SecondaryBackground)
                            .frame(width: 33, height: 33)
                            .overlay {
                                Image(systemName: showSuggestions ? "eye.slash" : "eye")
                                    .font(.system(.callout, design: .rounded).weight(.semibold))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                    .foregroundColor(Color.SubtitleText)
                                    .offset(y: 0.8)
                            }
                            .onTapGesture {
                                withAnimation {
                                    showSuggestions.toggle()
                                }
                            }

                        Spacer()

                        Circle()
                            .fill(!allCategories.isEmpty ? Color.IncomeGreen.opacity(0.23) : Color.clear)
                            .frame(width: 33, height: 33)
                            .overlay {
                                ZStack {
                                    Image(systemName: "arrow.right")
                                        .font(.system(.callout, design: .rounded).weight(.semibold))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                        .foregroundColor(!allCategories.isEmpty ? Color.IncomeGreen : Color.Outline.opacity(0.8))

                                    if allCategories.count == 0 {
                                        Circle()
                                            .stroke(Color.Outline.opacity(0.4), lineWidth: 1.3)
                                            .frame(width: 33, height: 33)
                                    }
                                }
                            }
                            .onTapGesture {
                                if allCategories.count > 0 {
                                    dismiss()
                                }
                            }
                    }
                    .frame(height: 35)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Text("Categories")
                            .font(.system(.title3, design: .rounded).weight(.medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 20, weight: .medium, design: .rounded))
                    }
                    .padding(20)

                } else {
                    HStack(spacing: 8) {
                        if mode == .settings {
                            Circle()
                                .fill(Color.SecondaryBackground)
                                .frame(width: 33, height: 33)
                                .overlay {
                                    Image(systemName: "chevron.left")
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color.SubtitleText)
                                        .offset(y: 0.8)
                                }
                                .onTapGesture {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                        } else {
                            Circle()
                                .fill(Color.SecondaryBackground)
                                .frame(width: 33, height: 33)
                                .overlay {
                                    Image(systemName: "chevron.down")
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                        .foregroundColor(Color.SubtitleText)
                                        .offset(y: 0.8)
                                }
                                .onTapGesture {
                                    dismiss()
                                }
                        }

                        Spacer()

                        Circle()
                            .fill(Color.SecondaryBackground)
                            .frame(width: 33, height: 33)
                            .overlay {
                                Image(systemName: showSuggestions ? "eye.slash" : "eye")
                                    .font(.system(.callout, design: .rounded).weight(.semibold))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.SubtitleText)
                                    .offset(y: 0.8)
                            }
                            .onTapGesture {
                                withAnimation {
                                    showSuggestions.toggle()
                                }
                            }

                        if categories.count > 1 {
                            if isEditing {
                                Circle()
                                    .fill(Color.IncomeGreen.opacity(0.23))
                                    .frame(width: 33, height: 33)
                                    .overlay {
                                        Image(systemName: "checkmark")
                                            .font(.system(.callout, design: .rounded).weight(.semibold))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.IncomeGreen)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }
                            } else {
                                Circle()
                                    .fill(Color.SecondaryBackground)
                                    .frame(width: 33, height: 33)
                                    .overlay {
                                        Image(systemName: "arrow.up.arrow.down")
                                            .font(.system(.callout, design: .rounded).weight(.semibold))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.SubtitleText)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: 35)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Text("Categories")
                            .font(.system(.title3, design: .rounded).weight(mode == .settings ? .semibold : .medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 20, weight: mode == .settings ? .semibold : .medium, design: .rounded))
                    }
                    .padding(20)
                }
            }

            VStack {
                if #available(iOS 16.0, *) {
                    List {
                        Section(header: Text(sectionHeader).foregroundColor(Color.SubtitleText)) {
                            if categories.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "tray")
                                        .font(.system(.largeTitle, design: .rounded).weight(.light))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                        .font(.system(size: 37, weight: .light))
                                        .foregroundColor(Color.SubtitleText)

                                    Group {
                                        if income {
                                            Text("no_income_categories")
                                        } else {
                                            Text("no_expense_categories")
                                        }
                                    }
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.SubtitleText)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 37)
                                .listRowBackground(Color.SettingsBackground)
                            } else {
                                ForEach(categories) { category in
                                    HStack(spacing: 10) {
                                        Text(category.wrappedEmoji)
                                            .font(.system(.subheadline, design: .rounded))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 15))
                                        Text(category.wrappedName)
                                            .font(.system(.body, design: .rounded))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 18.5, weight: .regular, design: .rounded))
                                            .lineLimit(1)
                                            .foregroundColor(toDelete == category ? Color.AlertRed : Color.PrimaryText)

                                        Spacer()

                                        if !income {
                                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(Color(hex: category.wrappedColour))
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                    .listRowBackground(Color.SettingsBackground)
                                    .listRowSeparatorTint(Color.Outline)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        toEdit = category
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            toDelete = category
                                        } label: {
                                            Image(systemName: "trash.fill")
                                        }
                                        .tint(Color.AlertRed)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            toEdit = category
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .tint(Color("Yellow"))
                                    }
                                }
                                .onMove(perform: moveItem)
                            }

//                                .onDelete(perform: deleteItem)
                        }

                        if showSuggestions {
                            SuggestedCategoriesView(income: income)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
                } else {
                    List {
                        Section(header: Text("\(income ? "INCOME" : "EXPENSE") CATEGORIES").foregroundColor(Color.SubtitleText)) {
                            if categories.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "tray")
                                        .font(.system(.largeTitle, design: .rounded).weight(.light))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                        .font(.system(size: 37, weight: .light))
                                        .foregroundColor(Color.SubtitleText)

                                    Text("No \(income ? "income" : "expense") categories found,\nclick the 'New' button to add some.")
                                        .font(.system(.body, design: .rounded).weight(.medium))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                        .font(.system(size: 17, weight: .medium, design: .rounded))
//                                        .italic()
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color.SubtitleText)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 37)
                                .listRowBackground(Color.SettingsBackground)
                            } else {
                                ForEach(categories) { category in
                                    HStack(spacing: 10) {
                                        Text(category.wrappedEmoji)
                                            .font(.system(.subheadline, design: .rounded))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 15))
                                        Text(category.wrappedName)
                                            .font(.system(.body, design: .rounded))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 18.5, weight: .regular, design: .rounded))
                                            .lineLimit(1)
                                            .foregroundColor(toDelete == category ? Color.AlertRed : Color.PrimaryText)

                                        Spacer()

                                        if !income {
                                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(Color(hex: category.wrappedColour))
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                    .listRowBackground(Color.SettingsBackground)
                                    .listRowSeparatorTint(Color.Outline)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        toEdit = category
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            toDelete = category
                                        } label: {
                                            Image(systemName: "trash.fill")
                                        }
                                        .tint(Color.AlertRed)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            toEdit = category
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .tint(Color("Yellow"))
                                    }
                                }
                                .onMove(perform: moveItem)
                            }

//                                .onDelete(perform: deleteItem)
                        }

                        if showSuggestions {
                            SuggestedCategoriesView(income: income)
                        }
                    }
                    .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
        .animation(.easeOut(duration: 0.2), value: showToast)
        .onChange(of: toDelete) { _ in
            if toDelete != nil {
                deleteMode = true
            }
        }
        .fullScreenCover(isPresented: $deleteMode, onDismiss: {
            toDelete = nil
        }) {
            ZStack(alignment: .bottom) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        deleteMode = false
                    }

                VStack(alignment: .leading, spacing: 1.5) {
                    Text("Delete '\(toDelete?.wrappedName ?? "")'?")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.PrimaryText)

                    Text("This action cannot be undone, and all \(toDelete?.wrappedName ?? "") transactions would be deleted.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.SubtitleText)
                        .padding(.bottom, 15)

                    Button {
                        withAnimation {
                            if let gonnaDelete = toDelete {
                                moc.delete(gonnaDelete)
                            }

                            dataController.save()
                        }

                        toDelete = nil
                        deleteMode = false

                    } label: {
                        Text("Delete")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                            .background(Color.AlertRed, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .padding(.bottom, 8)

                    Button {
                        withAnimation(.easeOut(duration: 0.7)) {
                            deleteMode = false
                            offset = 0
                        }

                    } label: {
                        Text("Cancel")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.PrimaryText.opacity(0.9))
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                            //                        .background(Color("13").opacity(0.23), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
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
                                deleteMode = false
                                offset = 0
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
        .sheet(item: $toEdit, onDismiss: {
            toEdit = nil
        }) { category in
            if #available(iOS 16.0, *) {
                EditCategoryAlert(toEdit: category, showRootToast: $showToast, rootToastTitle: $toastTitle, rootToastImage: $toastImage, positive: $positive, bottomSpacers: false)
                    .presentationDetents([.height(270)])
            } else {
                EditCategoryAlert(toEdit: category, showRootToast: $showToast, rootToastTitle: $toastTitle, rootToastImage: $toastImage, positive: $positive, bottomSpacers: true)
            }
        }
        .onChange(of: showToast) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .onChange(of: showSuggestions) { newValue in
            if !newValue {
                toastTitle = "Suggestions Hidden"
                toastImage = "eye.slash"
                showToast = true
                positive = true
            }
        }
    }

    private func moveItem(at sets: IndexSet, destination: Int) {
        let itemToMove = sets.first!

        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = categories[itemToMove].order
            while startIndex <= endIndex {
                categories[startIndex].order = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            categories[itemToMove].order = startOrder
        } else if destination < itemToMove {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = categories[destination].order + 1
            let newOrder = categories[destination].order
            while startIndex <= endIndex {
                categories[startIndex].order = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            categories[itemToMove].order = newOrder
        }

        do {
            dataController.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    init(income: Binding<Bool>, mode: CategoryViewMode, showToast: Binding<Bool>, toastTitle: Binding<String>, toastImage: Binding<String>, positive: Binding<Bool>) {
        _categories = FetchRequest<Category>(sortDescriptors: [
            SortDescriptor(\.order)
        ], predicate: NSPredicate(format: "income = %d", income.wrappedValue))

        _income = income
        _showToast = showToast
        _toastTitle = toastTitle
        _toastImage = toastImage
        _positive = positive
        self.mode = mode
    }
}

struct NewCategoryAlert: View {
    @Binding var income: Bool
    let budgetMode: Bool
    let bottomSpacers: Bool

    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @Environment(\.colorScheme) var systemColorScheme
    @EnvironmentObject var dataController: DataController

    @Namespace var animation

    // existing categories

    @FetchRequest(sortDescriptors: [SortDescriptor(\.order)], predicate: NSPredicate(format: "income = %d", false)) private var expenseCategories: FetchedResults<Category>
    @FetchRequest(sortDescriptors: [SortDescriptor(\.order)], predicate: NSPredicate(format: "income = %d", true)) private var incomeCategories: FetchedResults<Category>
    @State private var availableColours: [String] = Color.colorArray

    // state
    @State private var newName = ""
    @State private var newEmoji = ""
    @State private var showingColourPicker = false
    @State private var selectedColour: String = "#FFFFFF"

    @FocusState var focusedField: FocusedField?

    enum FocusedField: Hashable {
        case emoji, name
    }

    // toasts
    @State var outcome = CategoryError.none
    @State var showToast = false
    @State var toastTitle = ""
    @State var toastImage = ""
    @State var positive = false

    var toastColor: Color {
        positive ? Color.IncomeGreen : Color.AlertRed
    }

    var addButtonDisabled: Bool {
        return newName.trimmingCharacters(in: .whitespacesAndNewlines) == "" || newEmoji == ""
    }

    @State var showNativePicker: Bool = false
    @State var customSelectedColor = Color.white

//    @State var isFetching = false

    var body: some View {
        VStack {
            VStack {
                VStack {
                    if showToast {
                        HStack(spacing: 5) {
                            Image(systemName: toastImage)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(toastColor)

                            Text(toastTitle)
                                .font(.system(.callout, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .lineLimit(1)
//                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(toastColor)
                        }
                        .padding(6)
                        .background(toastColor.opacity(0.23), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .transition(AnyTransition.opacity.combined(with: .move(edge: .top)))
                        .frame(maxWidth: 200)
                    } else {
                        if expenseCategories.count == 24 {
                            Text("Income Category")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .padding(.top, 4)
                        } else if budgetMode {
                            Text("Expense Category")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .padding(.top, 4)
                        } else {
                            HStack(spacing: 0) {
                                Text("Expense")
                                    .font(.system(.callout, design: .rounded).weight(.semibold))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(income == false ? Color.PrimaryText : Color.SubtitleText)
                                    .padding(5)
                                    .padding(.horizontal, 7)
                                    .background {
                                        if income == false {
                                            Capsule()
                                                .fill(Color.SecondaryBackground)
                                                .matchedGeometryEffect(id: "TAB1", in: animation)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        DispatchQueue.main.async {
                                            withAnimation(.easeIn(duration: 0.15)) {
                                                income = false
                                            }
                                        }
                                    }

                                Text("Income")
                                    .font(.system(.callout, design: .rounded).weight(.semibold))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(income == true ? Color.PrimaryText : Color.SubtitleText)
                                    .padding(5)
                                    .padding(.horizontal, 7)
                                    .background {
                                        if income == true {
                                            Capsule()
                                                .fill(Color.SecondaryBackground)
                                                .matchedGeometryEffect(id: "TAB1", in: animation)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        DispatchQueue.main.async {
                                            withAnimation(.easeIn(duration: 0.15)) {
                                                income = true
                                            }
                                        }
                                    }
                            }
                            .padding(3)
                            .background(Capsule().fill(Color.PrimaryBackground).shadow(color: systemColorScheme == .light ? Color.Outline : Color.clear, radius: 6))
                            .overlay(Capsule().stroke(systemColorScheme == .light ? Color.clear : Color.Outline.opacity(0.4), lineWidth: 1.3))
                        }
                    }
                }
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(7)
                            .background(Color.SecondaryBackground, in: Circle())
                            .contentShape(Circle())
                    }
                }

                Spacer()

                ZStack {
                    EmojiTextField(text: $newEmoji)
                        .focused($focusedField, equals: .emoji)
                        .onReceive(Just(newEmoji), perform: { _ in
                            if String(self.newEmoji.onlyEmoji().suffix(1)) != self.newEmoji.onlyEmoji().prefix(1) {
                                self.newEmoji = String(self.newEmoji.onlyEmoji().suffix(1))
                            } else {
                                self.newEmoji = String(self.newEmoji.onlyEmoji().prefix(1))
                            }
                        })
                        .font(.system(size: 160))
                        .padding(8)
                        .frame(width: 80, height: 80, alignment: .center)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder((focusedField == .emoji && !showingColourPicker) ? Color.SubtitleText : Color.clear, lineWidth: 2.2)
                                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.SecondaryBackground))
                        }

                    if newEmoji == "" {
                        Image("emoji-happy")
                            .resizable()
                            .foregroundColor(Color.PrimaryText)
                            .frame(width: 35, height: 35, alignment: .center)
                            .allowsHitTesting(false)
                    }
                }

                Spacer()

                HStack {
                    if !income {
                        Button {
                            showingColourPicker = true
                        } label: {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color(hex: selectedColour))
                                .padding(8)
                                .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .frame(width: 50, height: 50)
                                .overlay {
                                    if showingColourPicker {
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .stroke(Color.SubtitleText, lineWidth: 2.2)
                                    }
                                }
                        }
                        .popover(present: $showingColourPicker, attributes: {
                            $0.position = .absolute(
                                originAnchor: .topLeft,
                                popoverAnchor: .bottomLeft
                            )
                            $0.rubberBandingMode = .none
                            $0.sourceFrameInset = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
                            $0.presentation.animation = .easeInOut(duration: 0.2)
                            $0.dismissal.animation = .easeInOut(duration: 0.3)
                        }) {
                            ColourPickerView(selectedColor: $selectedColour, showMenu: $showingColourPicker, showNativePicker: $showNativePicker)
                                .environment(\.managedObjectContext, self.moc)

                        } background: {
                            Color.PrimaryBackground.opacity(0.3)
                        }
                    }
//
//                    HStack(spacing: 8) {
//
//
//                        if isFetching {
//                            ProgressView()
//                                .padding(8)
//                        } else if newName != "" {
//                            Image(systemName: "xmark.circle.fill")
//                                .foregroundColor(Color.SubtitleText)
//                                .font(.system(size: 20, weight: .semibold))
//                                .padding(8)
//                                .onTapGesture {
//                                    withAnimation {
//                                        newName = ""
//                                    }
//                                }
//                        }
//                    }
                    NormalTextField(text: $newName, placeholder: "Category Name", action: verification)
                        .focused($focusedField, equals: .name)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .foregroundColor(Color.PrimaryText)

                        .frame(height: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder((focusedField == .name && !showingColourPicker) ? Color.SubtitleText : Color.clear, lineWidth: 2.2)
                                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.SecondaryBackground))
                        }
                    //
                    Button {
                        verification()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.LightIcon)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 50, height: 50)
                            .background(Color.DarkBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                }
            }
            .padding(13)
            .frame(maxHeight: bottomSpacers ? 350 : .infinity)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
        .animation(.easeOut(duration: 0.2), value: showToast)
        .onChange(of: expenseCategories.count) { _ in
            if expenseCategories.count == 24 {
                dismiss()
            }
        }
        .onChange(of: showToast) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .onChange(of: customSelectedColor) { _ in
            selectedColour = customSelectedColor.toHex() ?? "#FFFFFF"
        }
        .colorPickerSheet(isPresented: $showNativePicker, selection: $customSelectedColor, supportsAlpha: false, title: "")
        .onAppear {
            if expenseCategories.count == 24 {
                income = true
            }

            if !income {
                expenseCategories.forEach { category in
                    if availableColours.contains(category.wrappedColour) {
                        availableColours.remove(at: availableColours.firstIndex(of: category.wrappedColour) ?? 0)
                    }
                }

                if availableColours.isEmpty {
                    selectedColour = "#FFFFFF"
                } else {
                    selectedColour = availableColours[0]
                }
            }
        }
    }

    func verification() {
        let results = dataController.categoryCheck(name: newName, emoji: newEmoji, income: income)

        outcome = results.error

        if outcome != .none {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            switch outcome {
            case .incomplete:
                toastTitle = "Incomplete Entry"
                toastImage = "questionmark.app"
            case .missingEmoji:
                toastTitle = "Missing Emoji"
                toastImage = "person.fill"

                focusedField = .emoji
            case .missingName:
                toastTitle = "Missing Name"
                toastImage = "character.cursor.ibeam"

                focusedField = .name
            case .duplicate:
                toastTitle = "Duplicate Found"
                toastImage = "externaldrive"
            case .duplicateEmoji:
                toastTitle = "Duplicate Emoji"
                toastImage = "person.fill"

                focusedField = .emoji
            case .duplicateName:
                toastTitle = "Duplicate Name"
                toastImage = "character.cursor.ibeam"

                focusedField = .name
            default:
                return
            }

            positive = false
            showToast = true

        } else {
            toastTitle = "Added \(newName)"

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            if income {
                let category = Category(context: moc)
                category.name = newName.trimmingCharacters(in: .whitespaces).capitalized
                category.emoji = newEmoji
                category.dateCreated = Date.now
                category.id = UUID()
                category.colour = "IncomeGreen"
                category.order = results.order
                category.income = true
                dataController.save()

                newName = ""
                newEmoji = ""
            } else {
                let category = Category(context: moc)
                category.name = newName.trimmingCharacters(in: .whitespaces).capitalized
                category.emoji = newEmoji
                category.dateCreated = Date.now
                category.id = UUID()
                category.income = false

                category.colour = selectedColour
                category.order = results.order

                dataController.save()

                newName = ""
                newEmoji = ""

                availableColours = Color.colorArray
                expenseCategories.forEach { category in
                    if availableColours.contains(category.wrappedColour) {
                        availableColours.remove(at: availableColours.firstIndex(of: category.wrappedColour) ?? 0)
                    }
                }

                if availableColours.isEmpty {
                    selectedColour = "#FFFFFF"
                } else {
                    selectedColour = availableColours[0]
                }
            }

            if budgetMode {
                dismiss()
                return
            } else {
                focusedField = .emoji
                toastImage = "checkmark.circle.fill"
                positive = true
                showToast = true
            }
        }
    }

//    func GPTRecommendations(emoji: String, income: Bool) {
//        guard let url = URL(string: "https://api.openai.com/v1/completions") else {
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//
//        let parameters: [String:Any] = ["model":"text-davinci-003", "prompt":"What is the likely transaction category name for a \(income ? "income" : "expense") category with the emoji \(emoji)?", "temperature":0.9]
//
//        // Convert parameters into JSON data
//        let postData = try? JSONSerialization.data(withJSONObject: parameters)
//
//        request.httpBody = postData
//        request.addValue("Bearer \(Constants.openAPIKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        isFetching = true
//
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            DispatchQueue.main.async {
//
//                if let data = data {
//                    let decoder = JSONDecoder()
//
//                    do {
//                        // Decode data using your model structure
//                        let result = try decoder.decode(OpenAICompletionsResponse.self, from: data)
//                        self.newName = result.choices.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
//                        isFetching = false
//                    } catch {
//                        print("Failed to decode JSON")
//                        isFetching = false
//                    }
//                } else if let error = error {
//                    print("HTTP Request Failed \(error.localizedDescription)")
//                    isFetching = false
//                }
//            }
//        }
//
//        task.resume()
//    }

    init(income: Binding<Bool>, bottomSpacers: Bool, budgetMode: Bool = false) {
        _income = income
        self.budgetMode = budgetMode
        self.bottomSpacers = bottomSpacers
    }
}

struct EditCategoryAlert: View {
    let toEdit: Category
    @Binding var showRootToast: Bool
    @Binding var rootToastTitle: String
    @Binding var rootToastImage: String
    @Binding var positive: Bool

    let bottomSpacers: Bool

    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @Environment(\.colorScheme) var systemColorScheme
    @EnvironmentObject var dataController: DataController

    @Namespace var animation

    // existing categories

    @FetchRequest(sortDescriptors: [SortDescriptor(\.order)], predicate: NSPredicate(format: "income = %d", false)) private var expenseCategories: FetchedResults<Category>

    // state
    @State private var newName = ""
    @State private var newEmoji = ""
    @State private var showingColourPicker = false
    @State private var selectedColour: String = "#FFFFFF"

    @FocusState var focusedField: FocusedField?

    enum FocusedField: Hashable {
        case emoji, name
    }

    // toasts
    @State var outcome = CategoryError.none
    @State var showToast = false
    @State var toastTitle = ""
    @State var toastImage = ""

    // delete mode
    @State private var deleteMode = false
    @State private var toDelete: Category?
    var alertMessage: String {
        "Delete '" + (toDelete?.wrappedName ?? "") + "'?"
    }

    @State var showNativePicker: Bool = false
    @State var customSelectedColor = Color.white

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(7)
                            .background(Color.SecondaryBackground, in: Circle())
                            .contentShape(Circle())
                    }

                    Spacer()

                    if showToast {
                        HStack(spacing: 5) {
                            Image(systemName: toastImage)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.AlertRed)

                            Text(toastTitle)
                                .font(.system(.callout, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .lineLimit(1)
//                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.AlertRed)
                        }
                        .padding(6)
                        .background(Color.AlertRed.opacity(0.23), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .transition(AnyTransition.opacity.combined(with: .move(edge: .top)))
                        .frame(maxWidth: 200)
                    } else {
                        Text(toEdit.income ? "Income" : "Expense")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }

                    Spacer()

                    Button {
                        toDelete = toEdit
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.AlertRed)
                            .padding(7)
                            .background(Color.AlertRed.opacity(0.23), in: Circle())
                            .contentShape(Circle())
                    }
                }
                .frame(height: 30)

                Spacer()

                ZStack {
                    EmojiTextField(text: $newEmoji)
                        .focused($focusedField, equals: .emoji)
                        .onReceive(Just(newEmoji), perform: { _ in
                            if String(self.newEmoji.onlyEmoji().suffix(1)) != self.newEmoji.onlyEmoji().prefix(1) {
                                self.newEmoji = String(self.newEmoji.onlyEmoji().suffix(1))
                            } else {
                                self.newEmoji = String(self.newEmoji.onlyEmoji().prefix(1))
                            }
                        })
                        .font(.system(size: 160))
                        .padding(8)
                        .frame(width: 80, height: 80, alignment: .center)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder((focusedField == .emoji && !showingColourPicker) ? Color.SubtitleText : Color.clear, lineWidth: 2.2)
                                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.SecondaryBackground))
                        }

                    if newEmoji == "" {
                        Image("emoji-happy")
                            .resizable()
                            .foregroundColor(Color.PrimaryText)
                            .frame(width: 35, height: 35, alignment: .center)
                            .allowsHitTesting(false)
                    }
                }

                Spacer()

                HStack {
                    if !toEdit.income {
                        Button {
                            showingColourPicker = true
                        } label: {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color(hex: selectedColour))
                                .padding(8)
                                .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .frame(width: 50, height: 50)
                                .overlay {
                                    if showingColourPicker {
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .stroke(Color.SubtitleText, lineWidth: 2.2)
                                    }
                                }
                        }
                        .popover(present: $showingColourPicker, attributes: {
                            $0.position = .absolute(
                                originAnchor: .topLeft,
                                popoverAnchor: .bottomLeft
                            )
                            $0.rubberBandingMode = .none
                            $0.sourceFrameInset = UIEdgeInsets(top: -10, left: 0, bottom: 0, right: 0)
                            $0.presentation.animation = .easeInOut(duration: 0.2)
                            $0.dismissal.animation = .easeInOut(duration: 0.3)
                        }) {
                            ColourPickerView(selectedColor: $selectedColour, showMenu: $showingColourPicker, showNativePicker: $showNativePicker, toEdit: toEdit)
                                .environment(\.managedObjectContext, self.moc)

                        } background: {
                            Color.PrimaryBackground.opacity(0.3)
                        }
                    }

                    NormalTextField(text: $newName, placeholder: "Category Name", action: verification)
                        .focused($focusedField, equals: .name)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .frame(height: 50)
                        .foregroundColor(Color.PrimaryText)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder((focusedField == .name && !showingColourPicker) ? Color.SubtitleText : Color.clear, lineWidth: 2.2)
                                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.SecondaryBackground))
                        }

                    Button {
                        verification()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color.LightIcon)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 50, height: 50)
                            .background(Color.DarkBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                }
            }
            .padding(13)
            .frame(maxHeight: bottomSpacers ? 350 : .infinity)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.PrimaryBackground)
        .animation(.easeOut(duration: 0.2), value: showToast)
        .onChange(of: showToast) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .fullScreenCover(item: $toDelete, onDismiss: {
            toDelete = nil
        }) { category in
            DeleteCategoryAlert(toDelete: category, deleted: $deleteMode)
        }
        .onChange(of: expenseCategories.count) { _ in
            if expenseCategories.count == 24 {
                dismiss()
            }
        }
        .onChange(of: customSelectedColor) { _ in
            print("changed")
            selectedColour = customSelectedColor.toHex() ?? "#FFFFFF"
        }
        .colorPickerSheet(isPresented: $showNativePicker, selection: $customSelectedColor, supportsAlpha: false, title: "")
        .onChange(of: deleteMode) { _ in
            dismiss()
        }
        .onAppear {
            newName = toEdit.wrappedName
            newEmoji = toEdit.wrappedEmoji
            selectedColour = toEdit.wrappedColour
        }
    }

    func verification() {
        let results = dataController.categoryCheckEdit(name: newName, emoji: newEmoji, toEdit: toEdit)

        outcome = results.error

        if outcome != .none {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            switch outcome {
            case .incomplete:
                toastTitle = "Incomplete Entry"
                toastImage = "questionmark.app"
            case .missingEmoji:
                toastTitle = "Missing Emoji"
                toastImage = "person.fill"

                focusedField = .emoji
            case .missingName:
                toastTitle = "Missing Name"
                toastImage = "character.cursor.ibeam"

                focusedField = .name
            case .duplicate:
                toastTitle = "Duplicate Found"
                toastImage = "externaldrive"
            case .duplicateEmoji:
                toastTitle = "Duplicate Emoji"
                toastImage = "person.fill"

                focusedField = .emoji
            case .duplicateName:
                toastTitle = "Duplicate Name"
                toastImage = "character.cursor.ibeam"

                focusedField = .name
            default:
                return
            }

            showToast = true
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            if toEdit.income {
                toEdit.name = newName.trimmingCharacters(in: .whitespaces).capitalized
                toEdit.emoji = newEmoji

                dataController.save()
            } else {
                toEdit.name = newName.trimmingCharacters(in: .whitespaces).capitalized
                toEdit.emoji = newEmoji
                toEdit.colour = selectedColour

                dataController.save()
            }

            rootToastTitle = "Edited \(newName)"
            rootToastImage = "checkmark.circle.fill"
            positive = true
            showRootToast = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dismiss()
            }
        }
    }
}

struct DeleteCategoryAlert: View {
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let toDelete: Category
    @Binding var deleted: Bool
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
                Text("Delete '\(toDelete.wrappedName)'?")
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.PrimaryText)

                Text("This action cannot be undone.")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.SubtitleText)
                    .padding(.bottom, 15)
                    .accessibility(hidden: true)

                Button {
                    deleted = true
                    dismiss()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            moc.delete(toDelete)
                            dataController.save()
                        }
                    }

                } label: {
                    Text("Delete")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundColor(.white)
                        .frame(height: 45)
                        .frame(maxWidth: .infinity)
                        .background(Color.AlertRed, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .padding(.bottom, 8)

                Button {
                    withAnimation(.easeOut(duration: 0.7)) {
                        dismiss()
                    }

                } label: {
                    Text("Cancel")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.PrimaryText.opacity(0.9))
                        .frame(height: 45)
                        .frame(maxWidth: .infinity)
                        .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }
            .padding(13)
//            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
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
//            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
//                .onEnded({ value in
//                    if value.translation.height > 0 {
//                        dismiss()
//                    }
//                }))
            .padding(.horizontal, 17)
            .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
        }
        .edgesIgnoringSafeArea(.all)
        .background(BackgroundBlurView())
    }
}

struct SuggestedCategoriesView: View {
    let income: Bool
    @FetchRequest private var categories: FetchedResults<Category>

    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController

    var nameArray: [String] {
        var emptyArray = [String]()

        categories.forEach { category in
            emptyArray.append(category.wrappedName)
        }

        return emptyArray
    }

    var emojiArray: [String] {
        var emptyArray = [String]()

        categories.forEach { category in
            emptyArray.append(category.wrappedEmoji)
        }

        return emptyArray
    }

    var suggestions: [SuggestedCategory] {
        var holding = [SuggestedCategory]()

        if income {
            SuggestedCategory.incomes.forEach { category in
                if !nameArray.contains(category.name) && !emojiArray.contains(category.emoji) {
                    holding.append(category)
                }
            }
        } else {
            SuggestedCategory.expenses.forEach { category in
                if !nameArray.contains(category.name) && !emojiArray.contains(category.emoji) {
                    holding.append(category)
                }
            }
        }

        return holding
    }

    @State private var availableColours: [String] = Color.colorArray
    @State private var selectedColour = "1"

    var body: some View {
        if !suggestions.isEmpty {
            Section(header: Text("SUGGESTED").foregroundColor(Color.SubtitleText)) {
                ForEach(suggestions, id: \.self) { category in
                    HStack(spacing: 8) {
                        Text(category.emoji)
//                            .font(.system(size: 15))
                            .font(.system(.subheadline, design: .rounded))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        Text(LocalizedStringKey(category.name))
                            .font(.system(.body, design: .rounded))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 18.5, weight: .regular, design: .rounded))
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "plus")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(4)
                            .background(Color.SecondaryBackground, in: Circle())
                            .contentShape(Circle())
                    }
                    .padding(.vertical, 5)
                    .foregroundColor(Color.PrimaryText)
                    .listRowBackground(Color.SettingsBackground)
                    .listRowSeparatorTint(Color.Outline)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // double check

                        let (outcome, _) = dataController.categoryCheck(name: category.name, emoji: category.emoji, income: income)

                        if outcome != .none {
                            return
                        }

                        let impactMed = UIImpactFeedbackGenerator(style: .light)
                        impactMed.impactOccurred()

                        if !income {
                            let suggestedCategory = Category(context: moc)
                            suggestedCategory.name = NSLocalizedString(category.name, comment: "category name")
                            suggestedCategory.emoji = category.emoji
                            suggestedCategory.dateCreated = Date.now
                            suggestedCategory.id = UUID()
                            suggestedCategory.colour = selectedColour
                            suggestedCategory.order = (categories.last?.order ?? 0) + 1
                            suggestedCategory.income = false
                            dataController.save()

                            availableColours = Color.colorArray
                            categories.forEach { category in
                                if availableColours.contains(category.wrappedColour) {
                                    availableColours.remove(at: availableColours.firstIndex(of: category.wrappedColour) ?? 0)
                                }
                            }

                            if availableColours.isEmpty {
                                selectedColour = "#FFFFFF"
                            } else {
                                selectedColour = availableColours[0]
                            }
                        } else {
                            let suggestedCategory = Category(context: moc)
                            suggestedCategory.name = NSLocalizedString(category.name, comment: "category name")
                            suggestedCategory.emoji = category.emoji
                            suggestedCategory.dateCreated = Date.now
                            suggestedCategory.id = UUID()
                            suggestedCategory.colour = "#76FBB0"
                            suggestedCategory.order = (categories.last?.order ?? 0) + 1
                            suggestedCategory.income = true
                            dataController.save()
                        }
                    }
                }
            }
            .onAppear {
                if !income {
                    categories.forEach { category in
                        if availableColours.contains(category.wrappedColour) {
                            availableColours.remove(at: availableColours.firstIndex(of: category.wrappedColour) ?? 0)
                        }
                    }

                    if availableColours.isEmpty {
                        selectedColour = "#FFFFFF"
                    } else {
                        selectedColour = availableColours[0]
                    }
                }
            }
        }
    }

    init(income: Bool) {
        _categories = FetchRequest<Category>(sortDescriptors: [
            SortDescriptor(\.order)
        ], predicate: NSPredicate(format: "income = %d", income))

        self.income = income
    }
}

class UIEmojiTextField: UITextField {
    override var textInputMode: UITextInputMode? {
        .activeInputModes.first(where: { $0.primaryLanguage == "emoji" })
    }

    override func caretRect(for _: UITextPosition) -> CGRect {
        return CGRect.zero
    }
}

struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""

    func makeUIView(context: Context) -> UIEmojiTextField {
        let emojiTextField = UIEmojiTextField()
        emojiTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        emojiTextField.placeholder = placeholder
        emojiTextField.text = text
        emojiTextField.delegate = context.coordinator
        emojiTextField.font = UIFont(name: "HelveticaNeue", size: 50)
        emojiTextField.textAlignment = .center
        emojiTextField.endFloatingCursor()
        emojiTextField.becomeFirstResponder()
        return emojiTextField
    }

    func updateUIView(_ uiView: UIEmojiTextField, context _: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextField

        init(parent: EmojiTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.text = textField.text ?? ""
            }
        }
    }
}

struct NormalTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var action: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.placeholder = placeholder
        textField.autocapitalizationType = .words
        textField.text = text
        textField.delegate = context.coordinator

        textField.font = UIFont.roundedSpecial(ofStyle: .title2, weight: .medium, size: 17)
//
//        UIFont.rounded(ofSize: 20, weight: .medium)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context _: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NormalTextField

        init(parent: NormalTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.text = textField.text ?? ""
            }
        }

        func textFieldShouldReturn(_: UITextField) -> Bool {
            parent.action()

            return true
        }
    }
}

struct ColourPickerView: View {
    var selectedColours: [String]

    @Binding var showMenu: Bool
    @Binding var selectedColour: String

    @Binding var showNativePicker: Bool

    @State var customMode: Bool = false
    @State var customSelectedColor = Color.white

    @State var testing = false
    let columns = [
        GridItem(.fixed(40), spacing: 6),
        GridItem(.fixed(40), spacing: 6),
        GridItem(.fixed(40), spacing: 6),
        GridItem(.fixed(40), spacing: 6),
        GridItem(.fixed(40), spacing: 6),
        GridItem(.fixed(40))
    ]

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var colourScheme: Int = 0

    @Environment(\.colorScheme) var systemColorScheme

    var darkMode: Bool {
        (colourScheme == 0 && systemColorScheme == .dark) || colourScheme == 2
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Color.colorArray, id: \.self) { suggestedColor in
                if suggestedColor == "#" {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .pink]), center: .center))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(darkMode ? Color("AlwaysDarkBackground") : Color("AlwaysLightBackground"))
                            .padding(4)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(customSelectedColor)
                            .padding(8)

                        if customMode {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(customSelectedColor.luminance() > 0.5 ? Color.black : Color.white)
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.black)
                        }
                    }
                    .frame(width: 40, height: 40, alignment: .center)
                    .onTapGesture {
                        showMenu = false
                        showNativePicker = true
                    }
                } else {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(hex: suggestedColor))
                        .frame(height: 40)
                        .opacity(selectedColours.contains(suggestedColor) ? 0.2 : 1)
                        .onTapGesture {
                            if !selectedColours.contains(suggestedColor) {
                                withAnimation {
                                    selectedColour = suggestedColor
                                    customMode = false
                                    showMenu = false
                                }
                            }
                        }
                        .overlay {
                            if selectedColour == suggestedColor && !customMode {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.black)
                            }
                        }
                }
            }
        }
        .padding(6)
        .frame(width: 282)
        .background(RoundedRectangle(cornerRadius: 9).fill(darkMode ? Color("AlwaysDarkBackground") : Color("AlwaysLightBackground")).shadow(color: darkMode ? Color.clear : Color.gray.opacity(0.25), radius: 6))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(darkMode ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
    }

    init(selectedColor: Binding<String>, showMenu: Binding<Bool>, showNativePicker: Binding<Bool>, toEdit: Category? = nil) {
        _selectedColour = selectedColor
        _showMenu = showMenu
        _showNativePicker = showNativePicker

        if !Color.colorArray.contains(selectedColor.wrappedValue) {
            _customMode = State(initialValue: true)
            _customSelectedColor = State(initialValue: Color(hex: selectedColor.wrappedValue))
        }

        var selectedColours = [String]()

        let dataController = DataController.shared

        let categories = dataController.getAllCategories(income: false)

        categories.forEach { category in
            selectedColours.append(category.wrappedColour)
        }

        if let editted = toEdit {
            if !selectedColours.isEmpty {
                selectedColours.remove(at: selectedColours.firstIndex(of: editted.wrappedColour) ?? 0)
            }
        }

        self.selectedColours = selectedColours
    }
}

struct OpenAICompletionsResponse: Decodable {
    let id: String
    let choices: [OpenAICompletionsOptions]
}

struct OpenAICompletionsOptions: Decodable {
    let text: String
}
