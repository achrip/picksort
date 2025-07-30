//
//  ToolbarViw.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 30/07/25.
//

import Foundation
import SwiftUI

struct ToolbarView: View {
   
    @State private var tagFilename: String?
    @State private var tags: [String] = []
    @State private var selectedTags: Set<String> = []
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
                    ForEach(Array(selectedTags), id: \.self) { tag in
                        Text(tag)
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            
            TextField("Add tag...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onSubmit {
                    if let first = filteredTags.first {
                        selectedTags.insert(first)
                        searchText = ""
                    }
                }
            
            if !searchText.isEmpty {
                List(filteredTags, id: \.self) { tag in
                    Button(action: {
                        selectedTags.insert(tag)
                        searchText = ""
                    }) {
                        Text(tag)
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 100)
            }
        }
        .padding()
    }
    
    var filteredTags: [String] {
        if searchText.isEmpty {
            return tags
        } else {
            return tags.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

extension ToolbarView {
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
                let decodedTags = try JSONDecoder().decode([String].self, from: data)
                tags = decodedTags
            } catch {
                print("Failed to load JSON: \(error)")
            }
        }
    }
}

#Preview {
    ToolbarView()
}
