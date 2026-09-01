//
//  ActivityRingView.swift
//  Sophros
//
//  Created by Sohan Maurya on 07/08/26.
//

import SwiftUI

struct ActivityRingTip: Shape {
    var progress: Double
    var ringRadius: Double
    
    private var position: CGPoint {
        let progressAngle = Angle(degrees: (360.0 * progress) - 90.0)
        return CGPoint(
            x: ringRadius * cos(progressAngle.radians),
            y: ringRadius * sin(progressAngle.radians))
    }
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if progress > 0.0 {
            let frame = CGRect(
                x: position.x,
                y: position.y,
                width: rect.size.width,
                height: rect.size.height)
            path.addEllipse(in: frame)
        }
        return path
    }
}

struct ActivityRingView: View {
    var progress: Double            // comes from CoreData, changes non-animatedly
    var ringRadius: Double = 100.0
    var thickness: CGFloat = 20.0
    var startColor = Colormanager.Water.skyBlue
    var endColor = Colormanager.Water.deepBlue

    @State private var animatedProgress: Double = 0

    private var ringTipShadowOffset: CGPoint {
        let ringTipPosition = tipPosition(progress: animatedProgress, radius: ringRadius)
        let shadowPosition = tipPosition(progress: animatedProgress + 0.0075, radius: ringRadius)
        return CGPoint(x: shadowPosition.x - ringTipPosition.x,
                       y: shadowPosition.y - ringTipPosition.y)
    }

    private func tipPosition(progress: Double, radius: Double) -> CGPoint {
        let progressAngle = Angle(degrees: (360.0 * progress) - 90.0)
        return CGPoint(
            x: radius * cos(progressAngle.radians),
            y: radius * sin(progressAngle.radians))
    }

    var body: some View {
        let activityAngularGradient = AngularGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360.0 * animatedProgress))

        ZStack {
            Circle()
                .stroke(Colormanager.Water.lightBlue, lineWidth: thickness)
                .frame(width: CGFloat(ringRadius) * 2.0)
            Circle()
                .trim(from: 0, to: CGFloat(animatedProgress))
                .stroke(
                    activityAngularGradient,
                    style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .frame(width: CGFloat(ringRadius) * 2.0)
            ActivityRingTip(progress: animatedProgress,
                            ringRadius: Double(ringRadius))
                .fill(animatedProgress > 0.95 ? endColor : .clear)
                .frame(width: thickness, height: thickness)
                .shadow(color: animatedProgress > 0.95 ? .black.opacity(0.3) : .clear,
                        radius: 2.5,
                        x: ringTipShadowOffset.x,
                        y: ringTipShadowOffset.y)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { old, newValue in
            withAnimation(.easeInOut(duration: 0.4)) {
                animatedProgress = newValue
            }
        }
    }
}
