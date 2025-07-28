//
//  SidevarViewModel.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 28/07/25.
//

import SwiftUI

@Observable
class SidebarViewModel {
    
    var directories: [Directory]
    
    init() {
        self.directories = []
    }
    
    func addDirectory() {
        let panel = NSOpenPanel()
        panel.canCreateDirectories = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if !self.directories.contains(where: { $0.url == url }) {
                    let dirName = url.lastPathComponent
                    self.directories.append(Directory(url: url, name: dirName))
                }
            }
        }
    }
    
    func removeDirectory(_ directory: Directory) {
        if let index = directories.firstIndex(of: directory) {
            directories.remove(at: index)
        }
    }
}
