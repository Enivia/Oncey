//
//  ContentView.swift
//  Oncey
//
//  Created by enivia on 2026/4/22.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            AlbumsListView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Album.self, Moment.self], inMemory: true)
}
