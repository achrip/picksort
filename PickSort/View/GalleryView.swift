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
    @Binding var selectedImage: ImageItem?
    @Binding var imageItems: [ImageItem]
    
    var body: some View {
        VStack {
            if let url = selectedImage?.url {
                ThumbnailView(url: url, size: 400)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                
                Divider()
                
                carouselItems(imageItems)
            } else {
                Text(selectedDir == nil ? "Select a directory" : "No images found")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(selectedDir?.name ?? "Gallery")
        .task(id: selectedDir) {
            await loadImages(from: selectedDir)
        }
    }
}

// MARK: - UI Extensions
extension GalleryView {
    
    @ViewBuilder
    func carouselItems(_ images: [ImageItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 10) {
                        ForEach(images, id: \.self) { image in
                            ThumbnailView(url: image.url, size: 80)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.accentColor, lineWidth: selectedImage?.url == image.url ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedImage = image
                                }
                        }
                    }
                    .padding()
                }
                .frame(height: 100)
    }
    
}

// MARK: - Functional Extensions
extension GalleryView {
    
    func files(in directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
    }
    
    func thumbnail(for url: URL) -> NSImage? {
        let size = CGSize(width: 100, height: 100)
        return try? NSWorkspace.shared.icon(forFile: url.path)
            .resized(to: size)
            
    }
    
    func loadImages(from directory: Directory?) async {
        guard let url = directory?.url else {
            return
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            return
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        let validExtensions = ["jpg", "jpeg", "png", "heic", "tiff", "raf", "nef"]
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles])
            
            let loadedURLs = contents
                .filter { validExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            
            let items = loadedURLs.map { ImageItem(url: $0, tags: []) }
            
            await MainActor.run {
                imageItems = items
                selectedImage = items.first
            }
            
        } catch {
           print("Error scanning directory: \(error)")
        }
        
    }
}
