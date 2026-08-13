//
//  DraftWorkoutExercise.swift
//  Sophros
//
//  Created by Sohan Maurya on 10/08/26.
//

import Foundation

struct DraftWorkoutExercise: Identifiable {
    let id = UUID()
    var name = ""
    var sets = 3
    var reps = 10
    var weight = 10.0
}
