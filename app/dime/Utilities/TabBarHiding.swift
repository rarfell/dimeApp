//
//  TabBarHiding.swift
//  dime
//
//  Created by Rafael Soh on 18/9/22.
//

import Foundation

class TabBarManager: ObservableObject {
    @Published var hideTab = false
    @Published var inNavigationLink = false

    func navigationHideTab() {
        inNavigationLink = true
        hideTab = true
    }

    func navigationShowTab() {
        inNavigationLink = false
        hideTab = false
    }

    func scrollHideTab() {
        if !inNavigationLink {
            hideTab = true
        }
    }

    func scrollShowTab() {
        if !inNavigationLink {
            hideTab = false
        }
    }
}
