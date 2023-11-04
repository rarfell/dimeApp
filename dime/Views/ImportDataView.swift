//
//  ImportDataView.swift
//  dime
//
//  Created by Rafael Soh on 21/8/23.
//

import ConfettiSwiftUI
import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ColumnLabel {
    let image: String
    let label: String
}

enum ProcessingState {
    case loading, success, error
}

struct MatchedCategory: Hashable {
    let excelValue: String
    var income: Bool
    var category: Category?

    mutating func toggleIncome() {
        income = !income
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

struct ImportDataView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController

    @State private var exportSample = false
    @State private var importing = false

    @State private var data = ""
    @State private var rows = [[String]]()
    @State private var numberOfRows: Int = 0
    @State private var displayedColumns = [[String]]()
    @State private var columns = [[String]]()

    @State private var remainingColumns = [Int]()
    @State private var selectedColumns = [Int]()

    var indexColumnWidth: CGFloat {
        let additionalPadding: Double

        if dynamicTypeSize > .xLarge {
            additionalPadding = 10
        } else {
            additionalPadding = 0
        }

        if numberOfRows < 10 {
            return "9".widthOfRoundedString(size: 15, weight: .bold) + 16.0 + additionalPadding
        } else if numberOfRows < 100 {
            return "99".widthOfRoundedString(size: 15, weight: .bold) + 16.0 + additionalPadding
        } else {
            return "999".widthOfRoundedString(size: 15, weight: .bold) + 16.0 + additionalPadding
        }
    }

    @State var progress = 1

    @State var selectedColumn = 0
    @State var columnSelectionCompleted = false
    @State var sampleDateString = ""
    @State var dateFormatString = ""
    @State var validDateFormatString = false
    @State var uniqueCategories: [MatchedCategory] = .init()

    @State var processingState = ProcessingState.loading
    @State var errorMessage = "Invalid dates in date column."
    @State var confettiNumber = 0

    var numberOfLinkedCategories: Int {
        uniqueCategories.filter { $0.category != nil }.count
    }

    @State var showToast = false
    @State var toastMessage: String = "Invalid File"

    @State var showingCategoryView = false
    @State var pageIndex = 0

    // just for the adding of transactions
    @State var income = false

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var columnWidth: CGFloat {
        if dynamicTypeSize > .xLarge {
            return 150
        } else {
            return 100
        }
    }

    let instructions: [InstructionHeadings] = [
        InstructionHeadings(title: "Import transactions", subtitle: "Begin by adding a CSV file with 4 columns: amount, note, date, and category."),
        InstructionHeadings(title: "Assign category column", subtitle: "Select a column from your import that corresponds to the categories of your transactions."),
        InstructionHeadings(title: "Assign note column", subtitle: "Select a column from your import that corresponds to the notes/subtitles of your transactions."),
        InstructionHeadings(title: "Assign date column", subtitle: "Select a column from your import that corresponds to the dates of your transactions."),
        InstructionHeadings(title: "Assign amount column", subtitle: "Select a column from your import that corresponds to the values of your transactions."),
        InstructionHeadings(title: "Indicate date format", subtitle: "Referencing this article, state the format of the dates in the assigned column."),
        InstructionHeadings(title: "Link categories", subtitle: "Match values found in the 'Category' column to the corresponding categories in Dime."),
        InstructionHeadings(title: "Processing import", subtitle: "Please wait while we process your new transactions.")
    ]

    let labels: [ColumnLabel] = [
        ColumnLabel(image: "square.grid.2x2.fill", label: "Category"),
        ColumnLabel(image: "doc.plaintext.fill", label: "Note"),
        ColumnLabel(image: "calendar", label: "Date"),
        ColumnLabel(image: "dollarsign.circle.fill", label: "Amount")
    ]

    let pointers = ["Ensure that the values in the 'Amount' column do not contain any currency symbols.", "All dates should be of a consistent, recognizable format. If no timestamps are provided, the time of transaction will default to 12:00 am.", "Remove all commas in the 'Note' and 'Category' columns as they would disrupt the parsing of your file."]

    var incomeCategories: [Category] {
        dataController.getAllCategories(income: true)
    }

    var expenseCategories: [Category] {
        dataController.getAllCategories(income: false)
    }

    var body: some View {
        VStack(spacing: 0) {
            if progress == 8 {
                VStack(spacing: 15) {
                    switch processingState {
                    case .loading:
                        ProgressView()
                            .controlSize(.large)
                            .scaleEffect(0.8)

                        Text("Processing Import")
                            .font(.system(.title2, design: .rounded).weight(.medium))

//                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                    case .success:

                        Image(systemName: "checkmark")
                            .font(.system(.title2, design: .rounded).weight(.semibold))

//                            .font(.system(size: 21, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.IncomeGreen)
                            .frame(width: 35, height: 35)
                            .background(Color.IncomeGreen.opacity(0.3), in: Circle())

                        Text("Import Successful")
                            .font(.system(.title2, design: .rounded).weight(.medium))

//                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(Color.IncomeGreen)
                    case .error:
                        Image(systemName: "x")
                            .font(.system(.title2, design: .rounded).weight(.semibold))

//                            .font(.system(size: 21, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.AlertRed)
                            .frame(width: 35, height: 35)
                            .background(Color.Alert.opacity(0.3), in: Circle())

                        Text("Import Failed")
                            .font(.system(.title2, design: .rounded).weight(.medium))

//                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(Color.PrimaryText)

                        Text(errorMessage)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))

//                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color.SubtitleText)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                HStack {
                    if #available(iOS 17.0, *) {
                        Button {
                            if progress == 2 {
                                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    progress -= 1
                                }
                            } else if progress > 6 {
                                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    progress -= 1
                                }
                            } else if progress > 2 {
                                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    if let removedColumn = selectedColumns.popLast() {
                                        remainingColumns.append(removedColumn)
                                        remainingColumns.sort()
                                        selectedColumn = remainingColumns[0]
                                        columnSelectionCompleted = false

                                        progress -= 1
                                    }
                                }
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: progress > 1 ? "chevron.left" : "xmark")
                                .font(.system(.callout, design: .rounded).weight(.semibold))

                                .foregroundColor(Color.SubtitleText)
                                .padding(8)
                                .background(Color.SecondaryBackground, in: Circle())
                        }
                        .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol))
                    } else {
                        Button {
                            if progress > 1 {
                                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    progress -= 1
                                }
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: progress > 1 ? "chevron.left" : "xmark")
                                .font(.system(.callout, design: .rounded).weight(.semibold))
                                .foregroundColor(Color.SubtitleText)
                                .padding(8)
                                .background(Color.SecondaryBackground, in: Circle())
                        }
                    }

                    Spacer()

                    CustomCapsuleProgress(percent: Double(progress) / 7, width: 4, topStroke: Color.DarkBackground, bottomStroke: Color.SecondaryBackground)
                        .frame(width: 60)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

                .overlay {
                    if showToast {
                        HStack(spacing: 6.5) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.AlertRed)

                            Text(toastMessage)
                                .font(.system(.callout, design: .rounded).weight(.semibold))

//                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.AlertRed)
                        }
                        .padding(8)
                        .background(Color.AlertRed.opacity(0.23), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .transition(AnyTransition.opacity.combined(with: .move(edge: .top)))
                        .frame(width: 250)
                    }
                }
                .padding(.bottom, 50)
                .animation(.easeInOut, value: progress > 1)

                VStack(alignment: .leading, spacing: 5) {
                    if progress == 6 {
                        HStack {
                            Text("Indicate date format")
                                .foregroundColor(.PrimaryText)
                                .font(.system(.title2, design: .rounded).weight(.semibold))

//                                .font(.system(size: 26, weight: .semibold, design: .rounded))

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                        Text("Referencing \(makeAttributedString()), state the format of the dates in the assigned column.")
                            .foregroundColor(.SubtitleText)
                            .font(.system(.body, design: .rounded).weight(.medium))

//                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack {
                            Text(instructions[progress - 1].title)
                                .foregroundColor(Color.PrimaryText)
                                .font(.system(.title2, design: .rounded).weight(.semibold))

//                                .font(.system(size: 26, weight: .semibold, design: .rounded))

                            if progress == 7 {
                                Button {
                                    showingCategoryView = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                                        .foregroundColor(Color.SubtitleText)
                                        .padding(4)
                                        .background(Color.SecondaryBackground, in: Circle())
                                        .contentShape(Circle())
                                }
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                        Text(instructions[progress - 1].subtitle)
                            .foregroundColor(.SubtitleText)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: UIScreen.main.bounds.size.height / (dynamicTypeSize > .xLarge ? 5.3 : 5.8), alignment: .top)
                .padding(.bottom, 10)

                if progress == 1 {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))

//                            .font(.system(size: 15, weight: .semibold, design: .rounded))

                        Text("Additional Pointers")
                            .font(.system(.body, design: .rounded).weight(.semibold))

//                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .foregroundColor(Color.IncomeGreen)
                    .background(Color.IncomeGreen.opacity(0.23), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .padding(.bottom, 20)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            ForEach(pointers.indices, id: \.self) { index in
                                PointerView(number: index + 1, text: pointers[index])
                            }
                        }
                    }
                } else if progress < 6 {
                    VStack(spacing: 10) {
                        Text("Sampled Rows from Import CSV")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    ForEach(0 ..< (numberOfRows + 1)) { number in
                                        if number == 0 {
                                            Rectangle()
                                                .fill(Color.PrimaryBackground)
                                                .frame(width: indexColumnWidth, height: 30, alignment: .leading)
                                        } else {
                                            Text("\(number)")
                                                .foregroundStyle(Color.SubtitleText)
                                                .font(.system(.subheadline, design: .rounded).weight(.bold))

//                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .padding(.horizontal, 8)
                                                .frame(width: indexColumnWidth, height: 30, alignment: .leading)
                                                .overlay(Rectangle().stroke(Color.Outline, lineWidth: 1))
                                        }
                                    }
                                }
                                .background(Color.SecondaryBackground.opacity(0.6))

                                HStack(spacing: 0) {
                                    ForEach(displayedColumns.indices, id: \.self) { columnIndex in

                                        VStack(spacing: 0) {
                                            if selectedColumns.contains(columnIndex) {
                                                if let index = selectedColumns.firstIndex(of: columnIndex) {
                                                    HStack(spacing: 4.5) {
                                                        Image(systemName: labels[index].image)
                                                            .font(.system(.caption, design: .rounded).weight(.semibold))

//                                                            .font(.system(size: 12, weight: .semibold, design: .rounded))

                                                        Text(labels[index].label)
                                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .frame(width: columnWidth, height: 30, alignment: .leading)
                                                    .foregroundColor(Color(labels[index].label))
                                                    .background(Color(labels[index].label).opacity(0.23), in: RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))
                                                }
                                            } else {
                                                Rectangle()
                                                    .fill(Color.PrimaryBackground)
                                                    .frame(width: columnWidth, height: 30, alignment: .leading)
                                            }

                                            VStack(spacing: 0) {
                                                ForEach(displayedColumns[columnIndex], id: \.self) { value in
                                                    Text(value)
                                                        .foregroundStyle(Color.PrimaryText)
                                                        .font(.system(.subheadline, design: .rounded).weight(.medium))

//                                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                                        .padding(.horizontal, 8)
                                                        .frame(width: columnWidth, height: 30, alignment: .leading)
                                                        .overlay(Rectangle().stroke(Color.Outline, lineWidth: 1))
                                                    //
                                                }
                                            }
                                            .onTapGesture {
                                                if progress >= 2 {
                                                    if remainingColumns.contains(columnIndex) {
                                                        withAnimation {
                                                            selectedColumn = columnIndex
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .overlay(alignment: .leading) {
                                    if !columnSelectionCompleted && progress < 6 {
                                        VStack(spacing: 0) {
                                            HStack(spacing: 4.5) {
                                                Image(systemName: labels[progress - 2].image)
                                                    .font(.system(.caption, design: .rounded).weight(.semibold))

//                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))

                                                Text(labels[progress - 2].label)
                                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(.horizontal, 10)
                                            .frame(width: columnWidth + 2, height: 30, alignment: .leading)
                                            .foregroundColor(Color.LightIcon)
                                            .background(Color.DarkBackground, in: RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

                                            Rectangle()
                                                .stroke(Color.DarkBackground, lineWidth: 2)
                                                .frame(width: columnWidth)
                                                .frame(maxHeight: .infinity)
                                        }
                                        .offset(x: CGFloat(CGFloat(selectedColumn) * columnWidth))
                                    }
                                }
                            }
                            .padding(2)
                        }
                    }
                } else if progress == 6 {
                    VStack(spacing: 10) {
                        Text("Sample from 'Date' Column")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)

                        Text(sampleDateString)
                            .font(.system(.title3, design: .rounded).weight(.semibold))

//                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.PrimaryText)
                            .frame(width: 300, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(Color.Outline, lineWidth: 2)
                            )
                            .padding(.bottom, 30)

                        HStack(spacing: 7) {
                            Image(systemName: "calendar")
                                .font(.system(.callout, design: .rounded).weight(.semibold))

//                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.SubtitleText)

                            TextField("Date Format", text: $dateFormatString)
                                .foregroundColor(Color.PrimaryText)
                                .font(.system(.title3, design: .rounded).weight(.semibold))

//                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)

                            if validDateFormatString {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(.callout, design: .rounded).weight(.semibold))

//                                        .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.IncomeGreen)
                            } else if !validDateFormatString && dateFormatString != "" {
                                ProgressView()
                            }
                        }
                        .padding(.horizontal, 10)
                        .frame(width: 300, height: 40)
                        .background {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.SubtitleText, lineWidth: 2)
                                .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        }
                        .onChange(of: dateFormatString) { newValue in
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = newValue

                            if dateFormatter.date(from: sampleDateString) != nil {
                                validDateFormatString = true
                            } else {
                                validDateFormatString = false
                            }
                        }
                    }
                } else if progress == 7 {
                    VStack(spacing: 10) {
                        Text("\(numberOfLinkedCategories)/^[\(uniqueCategories.count) category](inflect: true) linked")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)

                        TabView(selection: $pageIndex) {
                            ForEach(uniqueCategories.indices, id: \.self) { categoryIndex in
                                VStack(spacing: 20) {
                                    HStack(spacing: 8) {
                                        Text(uniqueCategories[categoryIndex].excelValue)
                                            .font(.system(.title3, design: .rounded).weight(.semibold))

                                            .lineLimit(1)
//                                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color.PrimaryText)
//                                            .frame(height: 36)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .strokeBorder(Color.Outline, lineWidth: 2)
                                            )
                                            .minimumScaleFactor(0.7)

                                        if let unwrappedCategory = uniqueCategories[categoryIndex].category {
                                            HStack(spacing: 8) {
                                                Image(systemName: "triangle.fill")
                                                    .rotationEffect(Angle(degrees: 90))
                                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                                    .foregroundColor(Color.SubtitleText)

                                                HStack(spacing: 5) {
                                                    Text(unwrappedCategory.wrappedEmoji)
//                                                        .font(.system(size: 15))
                                                        .font(.system(.subheadline, design: .rounded))

                                                    Text(unwrappedCategory.wrappedName)
                                                        .font(.system(.title3, design: .rounded).weight(.semibold))

                                                        .lineLimit(1)

//                                                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                                                }
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
//                                                .frame(height: 36)
                                                .foregroundColor(Color(hex: unwrappedCategory.wrappedColour))
                                                .background(Color(hex: unwrappedCategory.wrappedColour).opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                .minimumScaleFactor(0.7)
                                            }
                                            .transition(.opacity)
                                        }
                                    }
                                    .drawingGroup()

                                    MatchCategoryStepperView(category: $uniqueCategories[categoryIndex].category, categories: uniqueCategories[categoryIndex].income ? incomeCategories : expenseCategories, pageIndex: $pageIndex, maxIndex: uniqueCategories.count)
                                        .overlay(alignment: .bottomTrailing) {
                                            let income = uniqueCategories[categoryIndex].income

                                            ZStack {
                                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                                    .fill(Color.PrimaryBackground)

                                                Image(systemName: income ? "plus" : "minus")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(income ? Color.IncomeGreen : Color.AlertRed)
                                                    .frame(width: 30, height: 30)
                                                    .background(income ? Color.IncomeGreen.opacity(0.23) : Color.AlertRed.opacity(0.23), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                                            }
                                            .frame(width: 30, height: 30)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                uniqueCategories[categoryIndex].income.toggle()
                                            }
                                            .padding(12)
                                        }

                                    Spacer()
                                }
                                .padding(10)
                                .tag(categoryIndex)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 390)
                    }
                }

                Spacer()

                if progress == 1 {
                    VStack(spacing: 13) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()

                            importing = true

                        } label: {
                            HStack(spacing: 6) {
                                Text("Import")
                                    .font(.system(.title3, design: .rounded).weight(.semibold))

//                                    .font(.system(size: 19, weight: .semibold, design: .rounded))

                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.LightIcon)
                            .background(Color.DarkBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        }
                        .buttonStyle(BouncyButton(duration: 0.2, scale: 0.8))

                        Button {
                            exportSample = true
                        } label: {
                            HStack(spacing: 6) {
//                                Image(systemName: "doc.text")
//                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                Text("Sample Sheet")
                                    .underline()
                                    .font(.system(.body, design: .rounded).weight(.semibold))

//                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(Color.SubtitleText)
                        }
                    }

                } else {
                    Button {
                        if progress == 7 {
                            if numberOfLinkedCategories == uniqueCategories.count {
                                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    progress += 1
                                }

                                importData()
                            } else {
                                showToast = true
                                toastMessage = "Unlinked Categories"
                            }

                        } else if progress > 5 {
                            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                progress += 1
                            }
                        } else {
                            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                guard !remainingColumns.isEmpty else { return }

                                if progress == 4 {
                                    let sample = displayedColumns[selectedColumn][0]

                                    guard sample.containsDigits else {
                                        showToast = true
                                        toastMessage = "Invalid Column"
                                        return
                                    }
                                }

                                if progress == 5 {
                                    let stringColumn = displayedColumns[selectedColumn]

                                    guard validateDoubles(strings: stringColumn) else {
                                        showToast = true
                                        toastMessage = "Invalid Column"
                                        return
                                    }
                                }

                                // remove from possible pool
                                let index = remainingColumns.firstIndex(of: selectedColumn) ?? 0
                                remainingColumns.remove(at: index)

                                // add to holding pool
                                selectedColumns.append(selectedColumn)

                                if progress < 5 {
                                    guard !remainingColumns.isEmpty else {
                                        showToast = true
                                        toastMessage = "Insufficient Columns"
                                        return
                                    }
                                    selectedColumn = remainingColumns[0]
                                }

                                // reset selected column

                                if progress == 5 {
                                    let dateColumnIndex = selectedColumns[2]
                                    sampleDateString = displayedColumns[dateColumnIndex][0]

                                    if let deducedFormat = deduceDateFormat(from: sampleDateString) {
                                        dateFormatString = deducedFormat
                                        validDateFormatString = true
                                    }

                                    let categoryColumnIndex = selectedColumns[0]
                                    uniqueCategories = columns[categoryColumnIndex].unique().map {
                                        MatchedCategory(excelValue: $0, income: false)
                                    }

                                    columnSelectionCompleted = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation {
                                            progress += 1
                                        }
                                    }
                                } else {
                                    progress += 1
                                }
                            }
                        }
                    } label: {
                        Text("Continue")
                            .font(.system(.title3, design: .rounded).weight(.semibold))

//                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.LightIcon)
                            .background(Color.DarkBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(BouncyButton(duration: 0.2, scale: 0.8))
                }
            }
        }
        .padding(20)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.keyboard)
        .background(Color.PrimaryBackground)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.commaSeparatedText]
        ) { result in
            switch result {
            case let .success(file):
                do {
                    if file.startAccessingSecurityScopedResource() {
                        guard let message = try String(data: Data(contentsOf: file), encoding: .utf8) else {
                            showToast = true
                            toastMessage = "Invalid File"
                            return
                        }

                        data = message

                        processCSV()

                        do {
                            file.stopAccessingSecurityScopedResource()
                        }
                    }
                } catch {}
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
        .sheet(isPresented: $exportSample) {
            if let url = Bundle.main.url(forResource: "sample", withExtension: "csv") {
                ActivityViewController(activityItems: [url])
            }
        }
        .sheet(isPresented: $showingCategoryView) {
            if #available(iOS 16.0, *) {
                NewCategoryAlert(income: $income, bottomSpacers: false, budgetMode: false)
                    .presentationDetents([.height(270)])
            } else {
                NewCategoryAlert(income: $income, bottomSpacers: true, budgetMode: false)
            }
        }
        .animation(.easeOut(duration: 0.2), value: showToast)
        .onChange(of: showToast) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .onChange(of: processingState) { newValue in
            if newValue == .success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        .confettiCannon(counter: $confettiNumber, num: 50, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 200)
    }

    func validateDoubles(strings: [String]) -> Bool {
        for string in strings {
            if let _ = Double(string) {
                // Valid double
            } else {
                return false // Invalid double found
            }
        }
        return true // All strings are valid doubles
    }

    func processCSV() {
        guard data.containsDigits else {
            showToast = true
            toastMessage = "Invalid File"
            return
        }

        var holdingRows = data.components(separatedBy: .newlines).filter { $0 != "" }

        if !holdingRows[0].containsDigits {
            holdingRows.removeFirst()
        }

        guard !holdingRows.isEmpty else {
            showToast = true
            toastMessage = "Invalid File"
            return
        }

        let values = holdingRows.map { $0.components(separatedBy: ",") }.filter { !$0.isEmpty }

        rows = values

        // Transpose rows to columns
        let maxColumnCount = values.map { $0.count }.max() ?? 0
//
        guard maxColumnCount > 3 else {
            showToast = true
            toastMessage = "Invalid File"
            return
        }

        var holdingColumns: [[String]] = Array(repeating: [], count: maxColumnCount)

        for row in values {
            for (index, value) in row.enumerated() {
                holdingColumns[index].append(value)
            }
        }

        columns = holdingColumns

        displayedColumns = holdingColumns.map { $0.prefix(8).map { $0 } }

        numberOfRows = displayedColumns[0].count

        remainingColumns = Array(0 ..< maxColumnCount)

        withAnimation {
            progress += 1
        }
    }

    func importData() {
        let categoryColumnIndex = selectedColumns[0]
        let noteColumnIndex = selectedColumns[1]
        let dateColumnIndex = selectedColumns[2]
        let amountColumnIndex = selectedColumns[3]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormatString

        let categoryDictionary: [String: Category] = Dictionary(uniqueKeysWithValues: uniqueCategories.map { ($0.excelValue, $0.category!) })

        rows.forEach { row in
//            let rowCategory = categoryDictionary[row[categoryColumnIndex]]
            if let transactionDate = dateFormatter.date(from: row[dateColumnIndex]) {
                if let rowCategory = categoryDictionary[row[categoryColumnIndex]] {
                    if let transactionAmount = Double(row[amountColumnIndex]) {
                        _ = dataController.newTransaction(note: row[noteColumnIndex], category: rowCategory, income: rowCategory.income, amount: abs(transactionAmount), date: transactionDate, repeatType: 0, repeatCoefficient: 1, delay: false)
                    } else {
                        processingState = .error
                        errorMessage = "Invalid values in amount column."
                        return
                    }
                } else {
                    processingState = .error
                    errorMessage = "Error occurred while matching categories."
                    return
                }
            } else {
                processingState = .error
                errorMessage = "Invalid dates in date column."
                return
            }
        }

        dataController.save()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                processingState = .success
                confettiNumber += 1
            }
        }
    }

    func deduceDateFormat(from dateString: String) -> String? {
        let dateFormats = ["yyyy-MM-dd", "dd-MM-yyyy", "MM-dd-yyyy",
                           "yyyy/MM/dd", "dd/MM/yyyy", "MM/dd/yyyy",
                           "yyyyMMdd", "ddMMyyyy", "MMddyyyy", "yyyy-MM-dd HH:mm:ss Z",
                           "dd/MM/yyyy HH:mm:ss"]

        let dateFormatter = DateFormatter()

        for dateFormat in dateFormats {
            dateFormatter.dateFormat = dateFormat
            if let _ = dateFormatter.date(from: dateString) {
                return dateFormat
            }
        }

        return nil
    }

    func makeAttributedString() -> AttributedString {
        var string = AttributedString("this article")
        string.foregroundColor = Color.PrimaryText
        string.link = URL(string: "https://pro.arcgis.com/en/pro-app/latest/help/mapping/time/convert-string-or-numeric-time-values-into-data-format.htm")
        string.underlineColor = UIColor(Color.PrimaryText)
        string.underlineStyle = .single

        return string
    }

    @ViewBuilder
    func PointerView(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.SecondaryBackground)

                Text("\(number)")
                    .font(.system(.body, design: .rounded).weight(.bold))

//                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
            }
            .frame(width: 25, height: 25)

            Text(text)
                .font(.system(.body, design: .rounded).weight(.medium))

//                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]?

    func makeUIViewController(context _: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

struct MatchCategoryStepperView: View {
    @Binding var category: Category?
    @Binding var pageIndex: Int
    var categories: [Category]
    var maxIndex: Int
//
//    @Environment(\.dynamicTypeSize) var dynamicTypeSize
//
//    var fontSize: CGFloat {
//        switch dynamicTypeSize {
//        case .xSmall:
//            return 14
//        case .small:
//            return 15
//        case .medium:
//            return 16
//        case .large:
//            return 17
//        case .xLarge:
//            return 19
//        case .xxLarge:
//            return 21
//        case .xxxLarge:
//            return 23
//        default:
//            return 23
//        }
//    }

    var body: some View {
        VStack {
            if categories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(.title, design: .rounded))

//                        .font(.system(size: 28, weight: .regular, design: .rounded))
                        .foregroundColor(Color.SubtitleText.opacity(0.7))
                        .padding(.top, 20)

                    Text("No remaining\ncategories.")
                        .font(.system(.callout, design: .rounded).weight(.medium))

//                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.SubtitleText.opacity(0.7))
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(getRows(), id: \.self) { rows in

                            HStack(spacing: 8) {
                                ForEach(rows) { row in

                                    // Row View....
                                    RowView(categoryInput: row)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(15)
        .frame(height: 250)
        .background(Color.Outline.opacity(0.3), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.Outline, lineWidth: 2)
        }
//        .background(Color.PrimaryBackground, in: )
    }

    func getRows() -> [[Category]] {
        var rows: [[Category]] = []
        var currentRow: [Category] = []

        var totalWidth: CGFloat = 0

        let screenWidth: CGFloat = UIScreen.main.bounds.width - 80

        categories.forEach { category in

            let roundedFont = UIFont.rounded(ofSize: UIFont.textStyleSize(.body), weight: .semibold)

            let attributes = [NSAttributedString.Key.font: roundedFont]

            let size = (category.fullName as NSString).size(withAttributes: attributes)

            totalWidth += (size.width + 10 + 10 + 8)

            if totalWidth > screenWidth {
                totalWidth = (!currentRow.isEmpty || rows.isEmpty ? (size.width + 10 + 10 + 8) : 0)

                rows.append(currentRow)
                currentRow.removeAll()
                currentRow.append(category)

            } else {
                currentRow.append(category)
            }
        }

        // Safe check...
        // if having any value storing it in rows...
        if !currentRow.isEmpty {
            rows.append(currentRow)
            currentRow.removeAll()
        }

        return rows
    }

    @ViewBuilder
    func RowView(categoryInput: Category) -> some View {
        Button {
            withAnimation {
                category = categoryInput
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation {
                    // remember to check for cap
                    if pageIndex < maxIndex - 1 {
                        pageIndex += 1
                    }
                }
            }

        } label: {
            HStack(spacing: 5) {
                Text(categoryInput.wrappedEmoji)
                    .font(.system(.footnote, design: .rounded))

//                    .font(.system(size: 13))
                Text(categoryInput.wrappedName)
                    .font(.system(.body, design: .rounded).weight(.semibold))

//                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundColor(category == categoryInput ? Color(hex: categoryInput.wrappedColour) : Color.PrimaryText)
            .background(category == categoryInput ? Color(hex: categoryInput.wrappedColour).opacity(0.35) : Color.PrimaryBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                if category != categoryInput {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.Outline,
                                      style: StrokeStyle(lineWidth: 1.5))
                }
            }
//            .opacity(category == nil ? 1 : (category == categoryInput ? 1 : 0.4))
        }
        .buttonStyle(BouncyButton(duration: 0.2, scale: 0.8))
    }

    init(category: Binding<Category?>?, categories: [Category], pageIndex: Binding<Int>, maxIndex: Int) {
        _category = category ?? Binding.constant(nil)
        _pageIndex = pageIndex
        self.categories = categories
        self.maxIndex = maxIndex
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
