//
//  ContentView.swift
//  BIKE-DE
//
//  Created by Louis Brouwer on 21/01/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var viewMode: ViewMode = .list
    
    enum ViewMode {
        case list, map
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("View Mode", selection: $viewMode) {
                    Image(systemName: "list.bullet").tag(ViewMode.list)
                    Image(systemName: "map").tag(ViewMode.map)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if viewMode == .list {
                    BikeListView()
                } else {
                    BikeMapView()
                }
            }
            .navigationTitle("Campus Bikes")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
}

