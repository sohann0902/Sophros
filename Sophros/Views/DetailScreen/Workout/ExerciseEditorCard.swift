//
//  ExerciseEditorCard.swift
//  Sophros
//
//  Created by Sohan Maurya on 11/08/26.
//


import SwiftUI

struct ExerciseEditorCard: View {
    @Binding var exercise: DraftWorkoutExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("", text: $exercise.name, prompt: Text("Exercise name"),
            axis: .vertical)
                .fontStyle(.body)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(Colormanager.card)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Colormanager.border, lineWidth: 1)
                    
                }

            HStack(spacing: 10) {
                WorkoutNumberField(
                    title: "SETS",
                    value: $exercise.sets,  format: .number,
                    keyboardType: .numberPad
                )

                WorkoutNumberField(
                    title: "REPS",
                    value: $exercise.reps,
                    format: .number,
                    keyboardType: .numberPad
                )
                
                WorkoutNumberField(
                    title: "WEIGHT (kg)",
                    value: $exercise.weight,
                    format: .number.precision(.fractionLength(0...2)),
                    keyboardType: .numberPad
                )

            }
        }
        .background(Color.clear)
    }
}

struct WorkoutNumberField<Value, Format>: View
where Format: ParseableFormatStyle,
      Format.FormatInput == Value,
      Format.FormatOutput == String {

    let title: String
    @Binding var value: Value
    let format: Format
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .fontStyle(.footer)

            TextField("0", value: $value, format: format)
                .fontStyle(.headline)
                .multilineTextAlignment(.center)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .foregroundStyle(Colormanager.Typography.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Colormanager.secondaryBg)
        .clipShape(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Colormanager.border.opacity(0.7), lineWidth: 1)
        }
    }
}


#Preview {
    ExerciseEditorCard(exercise: .constant(DraftWorkoutExercise()))
}
