//
//  Item.swift
//  PixelDays
//
//  Created by eevv on 9/21/25.
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
