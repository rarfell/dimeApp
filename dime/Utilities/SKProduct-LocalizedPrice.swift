//
//  SKProduct-LocalizedPrice.swift
//  dime
//
//  Created by Rafael Soh on 15/9/22.
//

import StoreKit

extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)!
    }
}
