//
//  NSImage+resized.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 28/07/25.
//

import Foundation
import SwiftUI

extension NSImage {
    func resized(to size: CGSize) -> NSImage {
        return NSImage(size: size, flipped: false) { (destinationRect) -> Bool in
            self.draw(in: destinationRect)
            return true
        }
    }
}
