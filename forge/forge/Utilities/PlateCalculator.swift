//
//  PlateCalculator.swift
//  forge
//
//  Created by Jwala Kompalli on 1/14/26.
//

import Foundation

struct PlateCalculator {
    static let barWeight: Double = 45.0
    static let availablePlates: [Double] = [45, 35, 25, 10, 5, 2.5]

    static func calculate(totalWeight: Double) -> String {
        // Weight must be at least the bar weight
        guard totalWeight >= barWeight else {
            return "Weight too low for barbell"
        }

        // Calculate weight needed per side
        let weightPerSide = (totalWeight - barWeight) / 2.0

        // If no plates needed
        if weightPerSide == 0 {
            return "Bar only (45 lbs)"
        }

        var remainingWeight = weightPerSide
        var platesList: [(weight: Double, count: Int)] = []

        // Greedily select plates from largest to smallest
        for plateWeight in availablePlates {
            let count = Int(remainingWeight / plateWeight)
            if count > 0 {
                platesList.append((weight: plateWeight, count: count))
                remainingWeight -= Double(count) * plateWeight
            }
        }

        // If we can't make exact weight
        if remainingWeight > 0.1 {
            return "Can't make exact weight"
        }

        // Format the result
        if platesList.isEmpty {
            return "Bar only (45 lbs)"
        }

        let platesString = platesList.map { plate in
            let plateStr = plate.weight == floor(plate.weight) ? "\(Int(plate.weight))" : "\(plate.weight)"
            return "\(plate.count)×\(plateStr)"
        }.joined(separator: " + ")

        return "Load per side: \(platesString)"
    }

    static func calculateCompact(totalWeight: Double) -> String? {
        guard totalWeight >= barWeight else { return nil }

        let weightPerSide = (totalWeight - barWeight) / 2.0

        if weightPerSide == 0 {
            return "Bar only"
        }

        var remainingWeight = weightPerSide
        var platesList: [String] = []

        for plateWeight in availablePlates {
            let count = Int(remainingWeight / plateWeight)
            if count > 0 {
                let plateStr = plateWeight == floor(plateWeight) ? "\(Int(plateWeight))" : "\(plateWeight)"
                platesList.append("\(count)×\(plateStr)")
                remainingWeight -= Double(count) * plateWeight
            }
        }

        if remainingWeight > 0.1 {
            return nil
        }

        if platesList.isEmpty {
            return "Bar only"
        }

        return platesList.joined(separator: " + ")
    }
}
