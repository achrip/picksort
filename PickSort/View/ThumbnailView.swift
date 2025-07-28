//
//  ThumbnailView.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 29/07/25.
//

import Foundation
import SwiftUI
import QuickLookThumbnailing

struct ThumbnailView: View {
    
    let url: URL
    let size: CGFloat
    
    @State private var thumbnail: NSImage?
    
    var body: some View {
        Group {
            if let image = thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .frame(width: size, height: size)
                    .background(Color.secondary.opacity(0.3))
                    .cornerRadius(3)
            }
        }
        .task(id: url) {
            await generateThumbnail()
        }
    }
}

extension ThumbnailView {
    
    @MainActor
    private func generateThumbnail() async {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: size * 2, height: size * 2),
            scale: NSScreen.main?.backingScaleFactor ?? 1.0,
            representationTypes: .all
        )
        
//        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error  in
//            if let representations = representation {
//                DispatchQueue.main.async {
//                    self.thumbnail = representation?.nsImage
//                }
//            } else if let error = error {
//                print("Error generating thumbnail: \(error.localizedDescription)")
//            }
//            
//        }
        do  {
           let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            self.thumbnail = representation.nsImage
        } catch {
            print("Failed to generate thumbnail: \(error.localizedDescription)")
            self.thumbnail = nil
        }
    }
}
