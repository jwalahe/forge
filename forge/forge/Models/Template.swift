//
//  Template.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftData

@Model
class Template {
    var id: UUID
    var name: String
    var createdAt: Date
    var lastUsedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        exercises: [TemplateExercise] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.exercises = exercises
    }

    var exerciseCount: Int {
        exercises.count
    }
}
