//
//  TemplateExercise.swift
//  forge
//
//  Created by Jwala Kompalli on 1/13/26.
//

import Foundation
import SwiftData

@Model
class TemplateExercise {
    var id: UUID
    var template: Template?
    var exercise: Exercise?
    var order: Int
    var defaultSets: Int

    init(
        id: UUID = UUID(),
        template: Template? = nil,
        exercise: Exercise? = nil,
        order: Int,
        defaultSets: Int = 3
    ) {
        self.id = id
        self.template = template
        self.exercise = exercise
        self.order = order
        self.defaultSets = defaultSets
    }
}
