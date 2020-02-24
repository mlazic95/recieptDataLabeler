//
//  Item.swift
//  MyFirstImageReader
//
//  Created by Marko Lazic on 2020-01-27.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation


class TextItem {
    var str: String
    var box: CGRect
    var rect: (CGPoint, CGPoint, CGPoint, CGPoint)
    var angle: CGFloat
    
    init(str: String, box: CGRect, rect: (CGPoint, CGPoint, CGPoint, CGPoint), angle: CGFloat) {
        self.str = str
        self.box = box
        self.rect = rect
        self.angle = angle
    }
}
