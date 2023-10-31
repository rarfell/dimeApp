//
//  NumberPad.swift
//  dime
//
//  Created by Yumi on 2023-10-29.
//

import SwiftUI

enum AssignedDecimal {
    case none, first, second
}

struct NumberPad: View {
    @Binding var price: Double
    @Binding var category: Category?
    @Binding var isEditingDecimal: Bool
    @Binding var decimalValuesAssigned: AssignedDecimal
    var showingNotePicker: Bool = false
    var submit: () -> Void
    
    @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var numberEntryType: Int = 1

    var numPadNumbers = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: proxy.size.height * 0.04) {
                ForEach(numPadNumbers, id: \.self) { array in
                    HStack(spacing: proxy.size.width * 0.05) {
                        ForEach(array, id: \.self) { singleNumber in
                            NumberButton(number: singleNumber, size: proxy.size)
                        }
                    }
                }
                HStack(spacing: proxy.size.width * 0.05) {
                    if numberEntryType == 1 {
                        Button {
                            deleteLastDigit()
                        } label: {
                            Image("tag-cross")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .frame(width: proxy.size.width * 0.3, height: proxy.size.height * 0.22)
                                .background(Color.DarkBackground)
                                .foregroundColor(Color.LightIcon)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(NumPadButton())
                    } else {
                        Button {
                            isEditingDecimal = true
                        } label: {
                            Text(".")
                                .font(.system(size: 34, weight: .regular, design: .rounded))
                                .frame(width: proxy.size.width * 0.3, height: proxy.size.height * 0.22)
                                .background(Color.SecondaryBackground)
                                .foregroundColor(Color.PrimaryText)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(NumPadButton())
                    }

                    NumberButton(number: 0, size: proxy.size)

                    Button {
                        submit()
                    } label: {
                        Group {
                            if #available(iOS 17.0, *) {
                                Image(systemName: "checkmark.square.fill")
                                    .font(.system(size: 30, weight: .medium, design: .rounded))
                                    .symbolEffect(.bounce.up.byLayer, value: price != 0 && category != nil)
                            } else {
                                Image(systemName: "checkmark.square.fill")
                                    .font(.system(size: 30, weight: .medium, design: .rounded))
                            }
                        }
                        .frame(width: proxy.size.width * 0.3, height: proxy.size.height * 0.22)
                        .foregroundColor(Color.LightIcon)
                        .background(Color.DarkBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(NumPadButton())
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .padding(.bottom, 15)
        .keyboardAwareHeight(showToolbar: showingNotePicker)
    }

    public func deleteLastDigit() {
        if numberEntryType == 1 {
            price = Double(Int(price * 10)) / 100
        } else if !isEditingDecimal {
            price = Double(Int(price / 10))
        } else {
            switch decimalValuesAssigned {
                case .none:
                    return
                case .first:
                    price = Double(Int(price))
                    isEditingDecimal = false
                    decimalValuesAssigned = .none
                case .second:
                    price = Double(Int(price * 10)) / 10
                    decimalValuesAssigned = .first
            }
        }
    }


    @ViewBuilder
    private func NumberButton(number: Int, size: CGSize) -> some View {
        Button {
            if price >= Double(Int.max) / 100 {
                return
            }
            if numberEntryType == 1 {
                price *= 10
                price += Double(number) / 100
            } else {
                if isEditingDecimal {
                    switch decimalValuesAssigned {
                        case .none:
                            price += Double(number) / 10
                            decimalValuesAssigned = .first
                        case .first:
                            price += Double(number) / 100
                            decimalValuesAssigned = .second
                        case .second:
                            return
                    }
//                    
//                    if !decimalValuesAssigned[0] {
//                        price += Double(number) / 10
//                        decimalValuesAssigned[0] = true
//                    } else if !decimalValuesAssigned[1] {
//                        price += Double(number) / 100
//                        decimalValuesAssigned[1] = true
//                    }
                } else {
                    price *= 10
                    price += Double(number)
                }
            }
        } label: {
            Text("\(number)")
                .font(.system(size: 34, weight: .regular, design: .rounded))
                .frame(width: size.width * 0.3, height: size.height * 0.22)
                .background(Color.SecondaryBackground)
                .foregroundColor(Color.PrimaryText)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .opacity(price >= Double(Int.max) / 100 ? 0.6 : 1)
        }
        .disabled(price >= Double(Int.max) / 100)
        .buttonStyle(NumPadButton())
    }
}

struct NumberPadTextView: View {
    @Binding var price: Double
    @Binding var isEditingDecimal: Bool
    @Binding var decimalValuesAssigned: AssignedDecimal

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }
    
    @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var numberEntryType: Int = 1
    
    public var amount: String {
        if numberEntryType == 1 {
            return String(format: "%.2f", price)
        }
        if isEditingDecimal {
            switch decimalValuesAssigned {
                case .none:
                    return String(format: "%.0f", price) + "."
                case .first:
                    return String(format: "%.1f", price)
                case .second:
                    return String(format: "%.2f", price)
            }
        }
        return String(format: "%.0f", price)
    }
    
    private var downsize: (big: CGFloat, small: CGFloat) {
        let size = UIScreen.main.bounds.width - 105
        if (amount.widthOfRoundedString(size: 32, weight: .regular)
          + currencySymbol.widthOfRoundedString(size: 20, weight: .light) + 4) > size {
          return (24, 16)
        } else if (amount.widthOfRoundedString(size: 44, weight: .regular)
          + currencySymbol.widthOfRoundedString(size: 25, weight: .light) + 4) > size {
          return (32, 20)
        } else if (amount.widthOfRoundedString(size: 56, weight: .regular)
          + currencySymbol.widthOfRoundedString(size: 32, weight: .light) + 4) > size {
          return (44, 25)
        }
        return (56, 32)
      }
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(currencySymbol)
                .font(.system(size: downsize.small, weight: .light, design: .rounded))
                .foregroundColor(Color.SubtitleText)
                .baselineOffset(getDollarOffset(big: downsize.big, small: downsize.small))
            if numberEntryType == 1 {
                Text("\(price, specifier: "%.2f")")
                    .font(.system(size: downsize.big, weight: .regular, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
            } else {
                Text("\(amount)")
                    .font(.system(size: 56, weight: .regular, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if numberEntryType == 2 {
                DeleteButton()
            }
        }
    }
    
    @ViewBuilder
   func DeleteButton() -> some View {
       Button {
         deleteLastDigit()
       } label: {
         Image(systemName: "delete.left.fill")
           .font(.system(size: 16, weight: .semibold))
           .foregroundColor(Color.SubtitleText)
           .padding(7)
           .background(Color.SecondaryBackground, in: Circle())
           .contentShape(Circle())
       }
       .disabled(price == 0)
   }

    public func deleteLastDigit() {
        if numberEntryType == 1 {
            price = Double(Int(price * 10)) / 100
        } else if !isEditingDecimal {
            price = Double(Int(price / 10))
        } else {
            switch decimalValuesAssigned {
                case .none:
                    return
                case .first:
                    price = Double(Int(price))
                    isEditingDecimal = false
                    decimalValuesAssigned = .none
                case .second:
                    price = Double(Int(price * 10)) / 10
                    decimalValuesAssigned = .first
            }
        }
    }
}
