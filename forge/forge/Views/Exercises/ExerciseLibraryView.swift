//
//  ExerciseLibraryView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI

struct ExerciseLibraryView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Exercise library will appear here")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Exercises")
        }
    }
}

#Preview {
    ExerciseLibraryView()
}
