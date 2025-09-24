//
//  ToolbarViw.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 30/07/25.
//

import Foundation
import SwiftUI

struct ToolbarView: View {
    
    @Binding var image: ImageItem?
    
    @State private var tagFilename: String?
    @State private var tags: [ImageTag] = []
    @State private var searchText: String = ""
    
    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 80))]
        
        VStack {
            HStack {
                Text("Tags File: \(tagFilename ?? "No file selected")")
                Button(tagFilename == nil ? "Select JSON" : "Reload JSON") {
                    selectAndLoadJSON()
                }
            }
            
            Divider()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(image?.tags ?? [], id: \.title) { tag in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text((tag.alternativeText?.isEmpty == false && tag.alternativeText != "-" ? tag.alternativeText! : tag.title))
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
//                            Spacer()
//                            Button {
////                                selectedTags.remove(tag)
//                                if let img = image {
//                                    img.tags.remove(tag)
//                                }
//                            } label: {
//                                Image(systemName: "xmark.circle.fill")
//                                    .foregroundColor(.red)
//                            }
//                            .buttonStyle(.plain)
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    var filteredTags: [ImageTag] {
        if searchText.isEmpty {
            return tags
        } else {
            return tags.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

extension ToolbarView {
    @ViewBuilder
    private func TagSearchBar() -> some View {
        TextField("Add tag...", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
            .onSubmit {
                if let first = filteredTags.first, var img = image {
                    //                        selectedTags.insert(first)
                    img.tags.insert(first)
                    image = img
                    searchText = ""
                }
            }
        
        if !searchText.isEmpty {
            List(filteredTags, id: \.title) { tag in
                Button(action: {
                    //                        selectedTags.insert(tag)
                    if var img = image {
                        img.tags.insert(tag)
                        image = img
                    }
                    searchText = ""
                }) {
                    Text(tag.title)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 100)
        }
    }
    
    func selectAndLoadJSON() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Select a JSON file"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                tagFilename = url.lastPathComponent
                let decodedTags = try JSONDecoder().decode([ImageTag].self, from: data)
                tags = decodedTags
            } catch {
                print("Failed to load JSON: \(error)")
            }
        }
    }
}

#Preview {
//    ToolbarView()
}
