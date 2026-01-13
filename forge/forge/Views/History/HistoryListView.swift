//
//  HistoryListView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI

struct HistoryListView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Your workout history will appear here")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryListView()
}
