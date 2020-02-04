//
//  LabelItem.swift
//  MyFirstImageReader
//
//  Created by Marko Lazic on 2020-02-03.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

class LabelItem {
    var text: String?
    var label: String?
    var price: Float?
    var amount: Int?
    
    init(text: String?, label: String?, price: Float?, amount: Int?) {
        self.text = text
        self.label = label
        self.price = price
        self.amount = amount
    }
}

