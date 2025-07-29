//
//  Directory.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 28/07/25.
//

import Foundation

struct Directory: Identifiable, Hashable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
}
