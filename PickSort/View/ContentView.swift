//
//  ContentView.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 28/07/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var sidebarVM = SidebarViewModel()
    @State private var selectedDir: Directory?
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: $sidebarVM, selectedDir: $selectedDir)
            .frame(width: 150)
        } content: {
            GalleryView(selectedDir: $selectedDir)
            .frame(minWidth: 400, maxWidth: .infinity)
        } detail: {
            Text("Controls")
                .navigationTitle("Detail")
                .navigationSplitViewColumnWidth(ideal: 250, max: 400)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    ContentView()
}
