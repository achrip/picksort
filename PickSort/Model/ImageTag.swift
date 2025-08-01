//
//  ImageTag.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 01/08/25.
//

import Foundation

struct ImageTag: Codable, Hashable {
    let title: String
    let alternativeText: String?
    
    enum NameCodingKeys: String, CodingKey {
        case title = "name"
        case alternativeText = "nickname"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NameCodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        alternativeText = try container.decodeIfPresent(String.self, forKey: .alternativeText)
    }
}
