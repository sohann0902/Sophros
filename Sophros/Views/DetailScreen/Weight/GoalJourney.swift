//
//  GoalJourney.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI

struct GoalJourney: View {
    let startingWeight: Double
    let currentWeight: Double
    let goalWeight: Double

    private var progress: Double {
        let totalChange = goalWeight - startingWeight
        guard totalChange != 0 else { return 0 }
        return min(1, max(0, (currentWeight - startingWeight) / totalChange))
    }
 
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let isGaining = goalWeight > startingWeight
            let start = CGPoint(x: 18, y: height * (isGaining ? 0.70 : 0.30))
            let end = CGPoint(x: width - 18, y: height * (isGaining ? 0.30 : 0.70))
            let current = CGPoint(
                x: start.x + ((end.x - start.x) * progress),
                y: start.y + ((end.y - start.y) * progress)
            )

            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: start)
                    path.addCurve(
                        to: end,
                        control1: CGPoint(x: width * 0.34, y: start.y),
                        control2: CGPoint(x: width * 0.72, y: end.y)
                    )
                }
                .stroke(Colormanager.Calendar.green.opacity(0.65), style: StrokeStyle(lineWidth: 3, lineCap: .round))

                Circle()
                    .fill(Colormanager.Calendar.green.opacity(0.35))
                    .frame(width: 11, height: 11)
                    .position(start)

                Circle()
                    .fill(Colormanager.Calendar.green)
                    .frame(width: 11, height: 11)
                    .position(current)

                Image(systemName: "flag.fill")
                    .foregroundStyle(Colormanager.Calendar.green)
                    .position(end)
            }
        }
    }
}
