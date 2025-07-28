//
//  SidebarView.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 28/07/25.
//

import Foundation
import SwiftUI

struct SidebarView: View {
    
    @Binding var viewModel: SidebarViewModel
    @Binding var selectedDir: Directory?
    
    var body: some View {
        VStack {
            List(selection: $selectedDir) {
                ForEach(viewModel.directories) { dir in
                    Label(dir.url.lastPathComponent, systemImage: "folder")
                        .tag(dir)
                        .contextMenu {
                            Button("Delete") {
                                viewModel.removeDirectory(dir)
                            }
                        }
                }
            }
            .listStyle(SidebarListStyle())
            
            Button {
                viewModel.addDirectory()
            } label: {
                Label("Add Folder", systemImage: "plus")
            }
            .padding()
        }
    }
}

#Preview {
    SidebarView(viewModel: .constant(.init()), selectedDir: .constant(nil))
}
