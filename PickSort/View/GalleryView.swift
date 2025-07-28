//
//  GalleryView.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 28/07/25.
//

import Foundation
import SwiftUI

struct GalleryView: View {
    
    @Binding var selectedDir: Directory?
    
    @State private var selectedImageURL: URL?
    
    private var imageFiles: [URL] {
        guard let url = selectedDir?.url else { return [] }
        let allFiles = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        let allSortedFiles = allFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
        return allSortedFiles.filter { ["jpg", "jpeg", "png", "heic", "tiff", "raf", "nef"].contains($0.pathExtension.lowercased())}
    }
    
    var body: some View {
        VStack {
            if let url = selectedImageURL {
                ThumbnailView(url: url, size: 400)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                
                Divider()
                
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 10) {
                        ForEach(imageFiles, id: \.self) { file in
                            ThumbnailView(url: file, size: 80)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.accentColor, lineWidth: selectedImageURL == file ? 3 : 0)
                                )
                                .onTapGesture {
                                    self.selectedImageURL = file
                                }
                        }
                    }
                    .padding()
                }
                .frame(height: 100)
            } else {
                Text(selectedDir == nil ? "Select a directory" : "No images found")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(selectedDir?.name ?? "Gallery")
        .onChange(of: selectedDir) { _, _ in
            self.selectedImageURL = imageFiles.first
        }
    }
}

extension GalleryView {
    
    func files(in directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
    }
    
    func thumbnail(for url: URL) -> NSImage? {
        let size = CGSize(width: 100, height: 100)
        return try? NSWorkspace.shared.icon(forFile: url.path)
            .resized(to: size)
            
    }
}
