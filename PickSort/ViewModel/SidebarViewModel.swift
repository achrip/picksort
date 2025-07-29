//
//  SidevarViewModel.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 28/07/25.
//

import SwiftUI

@Observable
class SidebarViewModel {
    
    private let directoryBookmarkKey = "directoryBookmarkList"
    
    var directories: [Directory]
    
    init() {
        self.directories = []
    }
    
    func addDirectory() {
        let panel = NSOpenPanel()
        panel.message = "Choose image folder: "
        panel.prompt = "Ok"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if !self.directories.contains(where: { $0.url == url }) {
                    let dirName = url.lastPathComponent
                    self.directories.append(Directory(url: url, name: dirName))
                    self.saveDirectoryPermission(for: url)
                }
            }
        }
    }
    
    func restoreSavedDirectory() {
        guard let bookmarkDatas = UserDefaults.standard.array(forKey: directoryBookmarkKey) as? [Data] else { return }

        for bookmarkData in bookmarkDatas {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                if isStale {
                    // Optionally: regenerate bookmark if needed
                    _ = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                }

                if url.startAccessingSecurityScopedResource() {
                    let dirName = url.lastPathComponent
                    if !self.directories.contains(where: { $0.url == url }) {
                        self.directories.append(Directory(url: url, name: dirName))
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("Error restoring directory bookmark: \(error)")
            }
        }
    }

    private func saveDirectoryPermission(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)

            var storedBookmarks = UserDefaults.standard.array(forKey: directoryBookmarkKey) as? [Data] ?? []
            storedBookmarks.append(bookmarkData)
            UserDefaults.standard.set(storedBookmarks, forKey: directoryBookmarkKey)
        } catch {
            print("Error saving directory bookmark: \(error)")
        }
    }
    
    func removeDirectory(_ directory: Directory) {
        if let index = directories.firstIndex(of: directory) {
            directories.remove(at: index)
        }
    }
}
