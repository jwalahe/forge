//
//  TemplateListView.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext

    @Query(sort: \Template.lastUsedAt, order: .reverse) private var templates: [Template]
    @State private var showingCreateTemplate = false

    var body: some View {
        List {
            if templates.isEmpty {
                emptyState
            } else {
                ForEach(templates) { template in
                    templateRow(template)
                }
                .onDelete(perform: deleteTemplates)
            }
        }
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateTemplate = true
                } label: {
                    Label("Create", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateView(modelContext: modelContext)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.3))
                .padding(.top, 60)

            Text("No Templates Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Save workouts as templates for quick start next time")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func templateRow(_ template: Template) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)

                Spacer()

                Text("\(template.exerciseCount) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let lastUsed = template.lastUsedAt {
                Text("Last used: \(lastUsed.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Exercise preview
            if !template.exercises.isEmpty {
                Text(exercisePreview(for: template))
                    .font(.caption)
                    .foregroundColor(.forgeAccent)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func exercisePreview(for template: Template) -> String {
        let exerciseNames = template.exercises
            .sorted { $0.order < $1.order }
            .compactMap { $0.exercise?.name }
            .prefix(3)

        if exerciseNames.count > 2 {
            return Array(exerciseNames.prefix(2)).joined(separator: ", ") + "..."
        }
        return exerciseNames.joined(separator: ", ")
    }

    private func deleteTemplates(at offsets: IndexSet) {
        let templateRepo = TemplateRepository(modelContext: modelContext)
        for index in offsets {
            templateRepo.deleteTemplate(templates[index])
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    return NavigationStack {
        TemplateListView(modelContext: container.mainContext)
    }
    .modelContainer(container)
}
