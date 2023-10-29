//
//  NumberPad.swift
//  dime
//
//  Created by Yumi on 2023-10-29.
//

import SwiftUI

struct NumberPad: View {
    @Binding var price: Double
    @Binding var category: Category?
    var showingNotePicker: Bool
    var submit: () -> Void
    
    @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var numberEntryType: Int = 1
    @State private var isEditingDecimal = false
    @State private var decimalValuesAssigned = [false, false]
    public var amount: String {
        if numberEntryType == 1 {
            return String(format: "%.2f", price)
        } else if isEditingDecimal {
            if decimalValuesAssigned[1] {
                return String(format: "%.2f", price)
            } else {
                return String(format: "%.1f", price)
            }
        }
        return String(format: "%.0f", price)
    }
    
    var numPadNumbers = [[1,2,3], [4,5,6], [7,8,9]]
    
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
            if decimalValuesAssigned[1] {
                price = Double(Int(price * 10)) / 10
                decimalValuesAssigned[1] = false
            } else {
                price = Double(Int(price))
                isEditingDecimal = false
                decimalValuesAssigned[0] = false
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
                    if !decimalValuesAssigned[0] {
                        price += Double(number) / 10
                        decimalValuesAssigned[0] = true
                    } else if !decimalValuesAssigned[1] {
                        price += Double(number) / 100
                        decimalValuesAssigned[1] = true
                    }
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
