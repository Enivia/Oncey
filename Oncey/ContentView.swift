//
//  ContentView.swift
//  Oncey
//
//  Created by enivia on 2026/4/22.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: HomeTab = .albums

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Albums", systemImage: "photo.stack", value: .albums) {
                NavigationStack {
                    AlbumsView()
                }
            }

            Tab("Moments", systemImage: "photo.on.rectangle.angled", value: .moments) {
                NavigationStack {
                    MomentsView()
                }
            }
        }
    }
}

private enum HomeTab {
    case albums
    case moments
}

#Preview {
    ContentView()
        .modelContainer(for: [Album.self, Moment.self], inMemory: true)
}
