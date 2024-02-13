//
//  FilterType.swift
//  Bonsai
//
//  Created by Rafael Soh on 3/6/22.
//

import Foundation

enum FilterType: String, CaseIterable {
    case all = "all entries"
    case category = "by category"
    case type = "by type"
    case day = "by day"
    case week = "by week"
    case month = "by month"
    case recurring = "recurring"
    case upcoming = "upcoming"

    static var imageDictionary: [FilterType: String] = [
        .all: "square.text.square.fill",
        .day: "d.square.fill",
        .week: "w.square.fill",
        .month: "m.square.fill",
        .category: "circle.grid.2x2.fill",
        .type: "centsign.circle.fill",
        .recurring: "repeat.circle.fill",
        .upcoming: "sun.min.fill",
    ]
}
