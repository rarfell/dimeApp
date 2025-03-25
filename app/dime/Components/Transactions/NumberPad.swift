//
//  NumberPad.swift
//  dime
//
//  Created by Yumi on 2023-10-29.
//

import SwiftUI
import CoreHaptics

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
    @AppStorage("haptics", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime"))
        var hapticType: Int = 1

    var numPadNumbers = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    @State private var engine: CHHapticEngine?

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
        .onAppear(perform: prepareHaptics)
    }

    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }

    func hapticTap() {
        // make sure that the device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        let hapticDict = [
            CHHapticPattern.Key.pattern: [
                [CHHapticPattern.Key.event: [
                    CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                    CHHapticPattern.Key.time: CHHapticTimeImmediate,
                    CHHapticPattern.Key.eventDuration: 1.0]
                ]
            ]
        ]

        do {
            let pattern = try CHHapticPattern(dictionary: hapticDict)

            let player = try engine?.makePlayer(with: pattern)

            engine?.notifyWhenPlayersFinished { _ in
                return .stopEngine
            }

            try engine?.start()
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }

//        
//        var events = [CHHapticEvent]()
//
//        // create one intense, sharp tap
//        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
//        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
//        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
//        events.append(event)
//
//        // convert those events into a pattern and play it immediately
//        do {
//            let pattern = try CHHapticPattern(events: events, parameters: [])
//            let player = try engine?.makePlayer(with: pattern)
//            try player?.start(atTime: 0)
//        } catch {
//            print("Failed to play pattern: \(error.localizedDescription).")
//        }
    }

    public func deleteLastDigit() {
        if numberEntryType == 1 {
            price = Double(Int(price * 10)) / 100
        } else if !isEditingDecimal {
            price = Double(Int(price / 10))
        } else {
            switch decimalValuesAssigned {
                case .none:
                    isEditingDecimal = false
                    return
                case .first:
                    price = Double(Int(price))
                    decimalValuesAssigned = .none
                case .second:
                    price = Double(Int(price * 10)) / 10
                    decimalValuesAssigned = .first
            }
        }
    }

    @ViewBuilder
    private func NumberButton(number: Int, size: CGSize) -> some View {
        var disabled: Bool {
            price >= 100000000
        }

        Button {
            if disabled {
                return
            }

            if hapticType == 2 {
                hapticTap()
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
                .opacity(disabled ? 0.6 : 1)
        }
        .disabled(disabled)
        .buttonStyle(NumPadButton())
    }
}

func splitDouble(_ num: Double) -> [String] {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    var str = formatter.string(from: NSNumber(value: num))!

    if floor(num) == num {
        str = String(format: "%.0f", num)
    }

    return str.map { String($0) }.filter { $0 != "." }
}

struct NumberPadTextView: View {
    @Binding var price: Double
    @Binding var isEditingDecimal: Bool
    @Binding var decimalValuesAssigned: AssignedDecimal

    @AppStorage("currency", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var currency: String = Locale.current.currencyCode!
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }
//
//    var displayNumbers: [String] {
//        return splitDouble(price)
//    }

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

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var largerFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall:
            return 46
        case .small:
            return 47
        case .medium:
            return 48
        case .large:
            return 50
        case .xLarge:
            return 56
        case .xxLarge:
            return 58
        case .xxxLarge:
            return 62
        default:
            return 50
        }
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Group {
                Text(currencySymbol)
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(Color.SubtitleText)

//                ForEach(displayNumbers, id: \.self) { number in
//                    Text(number)
//                        .font(.system(size: largerFontSize, weight: .regular, design: .rounded))
//                        .foregroundColor(Color.PrimaryText)
//                        .transition(AnyTransition.opacity.combined(with: .scale).combined(with: .move(edge: .trailing)))
//                }

                + Text(amount)
                    .font(.system(size: largerFontSize, weight: .regular, design: .rounded))
                    .foregroundColor(Color.PrimaryText)

            }
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .padding(.horizontal, numberEntryType == 2 ? 40 : 0)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if numberEntryType == 2 {
                DeleteButton()
            }
        }
//        .animation(.snappy.delay(0.1), value: displayNumbers)
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
       .disabled(price == 0 && !isEditingDecimal)
   }

    public func deleteLastDigit() {
        if numberEntryType == 1 {
            price = Double(Int(price * 10)) / 100
        } else if !isEditingDecimal {
            price = Double(Int(price / 10))
        } else {
            switch decimalValuesAssigned {
                case .none:
                    isEditingDecimal = false
                    return
                case .first:
                    price = Double(Int(price))
                    decimalValuesAssigned = .none
                case .second:
                    price = Double(Int(price * 10)) / 10
                    decimalValuesAssigned = .first
            }
        }
    }
}
