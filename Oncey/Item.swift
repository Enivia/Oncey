//
//  Item.swift
//  Oncey
//
//  Created by enivia on 2026/4/22.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
