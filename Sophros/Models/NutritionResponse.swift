//
//  NutritionResponse.swift
//  Sophros
//
//  Created by Sohan Maurya on 19/08/26.
//

import Foundation

struct NutritionResponse: Decodable {
    let items: [NutritionItem]
}

struct NutritionItem: Decodable {
    let name: String
    let calories: Double
    let servingSizeGrams: Double
    let fat: Double
    let protein: Double
    let carbs: Double
    let fiber: Double
    let sugar: Double

    enum CodingKeys: String, CodingKey {
        case name
        case calories
        case servingSizeGrams = "serving_size_g"
        case fat = "fat_total_g"
        case protein = "protein_g"
        case carbs = "carbohydrates_total_g"
        case fiber = "fiber_g"
        case sugar = "sugar_g"
    }
}
