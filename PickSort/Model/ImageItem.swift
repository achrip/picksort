//
//  ImageItem.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 30/07/25.
//

import Foundation

struct ImageItem: Identifiable {
    let id: UUID
    let url: URL
    var tags: Set<String>
}
