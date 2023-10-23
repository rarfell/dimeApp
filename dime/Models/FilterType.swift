//
//  FilterType.swift
//  Bonsai
//
//  Created by Rafael Soh on 3/6/22.
//

import Foundation

enum FilterType: String, CaseIterable {
    case all = "all entries"
    case type = "by type"
    case day = "by day"
    case week = "by week"
    case month = "by month"
    case category = "by category"
    case recurring = "recurring"
    case upcoming = "upcoming"
    
    static var imageDictionary: [String:String] = [
        "all entries":"square.text.square.fill",
        "by type":"centsign.circle.fill",
        "by category":"circle.grid.2x2.fill",
        "by day":"d.square.fill",
        "by week":"w.square.fill",
        "by month":"m.square.fill",
        "recurring":"repeat.circle.fill",
        "upcoming":"sun.min.fill"
    ]
}
