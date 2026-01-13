//
//  WorkoutHomeView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI

struct WorkoutHomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("FORGE")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Button {
                    // Start workout action
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.primaryButtonHeight)
                    .background(Color.forgeAccent)
                    .foregroundColor(.white)
                    .cornerRadius(AppConstants.cornerRadius)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
        }
    }
}

#Preview {
    WorkoutHomeView()
}
