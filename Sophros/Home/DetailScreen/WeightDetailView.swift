//
//  WeightDetailView.swift
//  Sophros
//
//  Created by Sohan Maurya on 01/09/26.
//

import SwiftUI
import CoreData

struct WeightDetailView: View {
    let card: DashboardCard
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRange: WeightRange = .month
    @State private var showingLogWeight = false
    @State private var showingGoalEditor = false
    @State private var weightText = ""
    @State private var goalText = ""
    @State private var showingGoalOnboarding = false
    @State private var onboardingGoalText = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeightEntry.createdAt, ascending: false)],
        animation: .easeInOut
    )
    
    private var entries: FetchedResults<WeightEntry>
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \WeightGoal.createdAt,
                ascending: false
            )
        ],
        animation: .default
    )
    
    private var weightGoals: FetchedResults<WeightGoal>

    private var currentWeight: Double? { entries.first?.weight }
    private var startingWeight: Double? { entries.last?.weight }
    private var goalWeight: Double? { weightGoals.first?.weight }
    private var remainingWeight: Double? {
        guard let currentWeight, let goalWeight else { return nil }
        return abs(goalWeight - currentWeight)
    }

    var body: some View {
        ZStack {
            Colormanager.baseBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    currentWeightHero
                    trendCard
                    
                Picker("Range", selection: $selectedRange) {
                    ForEach(WeightRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .symbolColorRenderingMode(.flat)
                .tint(.white)
                .colorMultiply(Colormanager.Sleep.lavender)
                .padding(.horizontal, 24)

                    goalCard

                    Button {
                        showingLogWeight = true
                    } label: {
                        Label("Log weight", systemImage: "plus")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 19)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 24)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }

            if showingGoalOnboarding {
                FeatureOnboardingOverlay(
					tint: Colormanager.Sleep.periwinkle, background: .red,
                    title: "Set your target weight",
                    message: "Choose a weight you want to work toward. You can update this at any time.",
                    actionTitle: "Save target",
                    actionEnabled: validOnboardingGoal,
                    content: {
                        OnboardingNumericField(title: "Target weight", unit: "kg", placeholder: "65", value: $onboardingGoalText)
                    },
                    action: saveOnboardingGoal
                )
            }
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { showingGoalOnboarding = weightGoals.isEmpty }
        .alert("Log weight", isPresented: $showingLogWeight) {
            TextField("Weight in kg", text: $weightText)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { weightText = "" }
            Button("Save") { saveWeight() }
        } message: {
            Text("Enter your current weight in kilograms.")
        }
        .alert("Set goal", isPresented: $showingGoalEditor) {
            TextField("Goal weight in kg", text: $goalText)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { goalText = "" }
            Button("Save") { setGoal() }
        } message: {
            Text("Choose the weight you want to work toward.")
        }
    }

    private var currentWeightHero: some View {
        
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(currentWeight ?? 0, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                    Text("kg").font(.title2.bold())
                }
                
                
                Text("Current weight")
            }
            .foregroundStyle(Colormanager.Sleep.periwinkle)

            Spacer()
            
            // image
        }
        .padding(.horizontal, 32)
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your journey").font(.title2.bold())
                .foregroundStyle(Colormanager.Sleep.lavender)
            WeightTrendSection(range: selectedRange)
                .id(selectedRange)
                .frame(height: 230)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Colormanager.Sleep.lavender.opacity(0.22), Colormanager.Sleep.lavender.opacity(0.18), Colormanager.Sleep.lavender.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 24)
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your goal").font(.title3.bold())
                Spacer()
                Button {
                    goalText = String(format: "%.1f", goalWeight ?? 0)
                    showingGoalEditor = true
                } label: {
                    Image(systemName: "square.and.pencil.circle.fill").resizable()
                        .scaledToFit()
                        .frame(height: 30)
                }
            }
            
            Spacer()
            
            HStack(alignment: .center) {
                VStack {
                    Text(goalWeight ?? 0, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                    Text("kg").font(.title3.bold())
                }
                
                Spacer()
                
                if let startingWeight, let currentWeight, let goalWeight {
                    GoalJourney(
                        startingWeight: startingWeight,
                        currentWeight: currentWeight,
                        goalWeight: goalWeight
                    )
                    .frame(height: 100)
                }
                
            }

           
        }
        .foregroundStyle(Colormanager.Sleep.lavender)
        .padding(24)
        .background(
            LinearGradient(
                colors: [Colormanager.Sleep.lavender.opacity(0.22), Colormanager.Sleep.lavender.opacity(0.18), Colormanager.Sleep.lavender.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 24)
    }

    private func saveWeight() {
        guard let value = Double(weightText), value > 0 else { return }
        let entry = WeightEntry(context: context)
        entry.id = UUID()
        entry.weight = value
        entry.createdAt = .now
        entry.updatedAt = .now
        try? context.save()
        weightText = ""
    }

    private func setGoal() {
        guard let value = Double(goalText), value > 0 else { return }

        let goal = weightGoals.first ?? WeightGoal(context: context)
        if goal.id == nil {
            goal.id = UUID()
            goal.createdAt = .now
        }
        goal.weight = value
        goal.updatedAt = .now
        try? context.save()
        goalText = ""
    }

    private var validOnboardingGoal: Bool {
        guard let value = Double(onboardingGoalText) else { return false }
        return (20...300).contains(value)
    }

    private func saveOnboardingGoal() {
        guard validOnboardingGoal else { return }
        goalText = onboardingGoalText
        setGoal()
        onboardingGoalText = ""
        showingGoalOnboarding = false
    }
}

#Preview {
    WeightDetailView(card: DashboardCard.cards.last!)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


enum WeightRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: Self { self }

    func interval(calendar: Calendar = .autoupdatingCurrent) -> DateInterval {
        switch self {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: .now)!
        case .month:
            return calendar.dateInterval(of: .month, for: .now)!
        case .year:
            return calendar.dateInterval(of: .year, for: .now)!
        }
    }

    func bucketDate(
        for date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date {
        switch self {
        case .week:
            return calendar.startOfDay(for: date)

        case .month:
            return calendar.dateInterval(of: .weekOfYear, for: date)!.start

        case .year:
            return calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)
            )!
        }
    }
}

struct WeightPoint: Identifiable {
    let date: Date
    let weight: Double

    var id: Date { date }
}

struct WeightTrendSection: View {
    let range: WeightRange

    @FetchRequest private var entries: FetchedResults<WeightEntry>

    init(range: WeightRange) {
        self.range = range

        let interval = range.interval()

        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            interval.start as NSDate,
            interval.end as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WeightEntry.createdAt, ascending: true)
        ]

        _entries = FetchRequest(fetchRequest: request, animation: .easeInOut)
    }

    var points: [WeightPoint] {
        let calendar = Calendar.autoupdatingCurrent

        let grouped = Dictionary(grouping: entries) { entry in
            range.bucketDate(for: entry.createdAt ?? .distantPast, calendar: calendar)
        }

        return grouped.compactMap { bucket, entriesInBucket in
            // If they log twice in one day, display the most recent entry.
            guard let latest = entriesInBucket.max(by: {
                ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
            }) else {
                return nil
            }

            // Use the real measurement timestamp for its x-position. This keeps
            // the first partial week of a month visible inside the chart domain.
            return WeightPoint(
                date: latest.createdAt ?? bucket,
                weight: latest.weight
            )
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        Group {
            if points.isEmpty {
                ContentUnavailableView(
                    "No weight entries yet",
                    systemImage: "scalemass",
                    description: Text("Log a weight to see your progress here.")
                )
            } else {
                WeightTrendChart(
                    points: points,
                    interval: range.interval()
                )
            }
        }
    }
}


struct WeightTrendChart: View {
    let points: [WeightPoint]
    let interval: DateInterval

    private var yDomain: ClosedRange<Double> {
        let weights = points.map(\.weight)
        guard let minimum = weights.min(), let maximum = weights.max() else {
            return 0...1
        }

        let padding = max(0.5, (maximum - minimum) * 0.25)
        return (minimum - padding)...(maximum + padding)
    }

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)

            ZStack {

                TrendLineShape(points: points, interval: interval, yDomain: yDomain)
                    .stroke(Colormanager.Sleep.lavender, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                ForEach(points) { point in
                    ZStack {
                        Circle()
                            .fill(Colormanager.Sleep.lavender)
                            .frame(width: 9, height: 9)
                            .position(TrendGeometry.position(for: point, in: rect, interval: interval, yDomain: yDomain))
                    }
                }
            }
            .clipShape(Rectangle())
        }
    }
}

private enum TrendGeometry {
    static func position(for point: WeightPoint, in rect: CGRect, interval: DateInterval, yDomain: ClosedRange<Double>) -> CGPoint {
        let xProgress = min(1, max(0, point.date.timeIntervalSince(interval.start) / interval.duration))
        let yProgress = (point.weight - yDomain.lowerBound) / (yDomain.upperBound - yDomain.lowerBound)
        return CGPoint(x: rect.width * xProgress, y: rect.height * (1 - yProgress))
    }
}

private struct TrendLineShape: Shape {
    let points: [WeightPoint]
    let interval: DateInterval
    let yDomain: ClosedRange<Double>

    func path(in rect: CGRect) -> Path {
        guard let first = points.first else { return Path() }
        var path = Path()
        path.move(to: TrendGeometry.position(for: first, in: rect, interval: interval, yDomain: yDomain))
        for point in points.dropFirst() {
            path.addLine(to: TrendGeometry.position(for: point, in: rect, interval: interval, yDomain: yDomain))
        }
        return path
    }
}

private struct TrendAreaShape: Shape {
    let points: [WeightPoint]
    let interval: DateInterval
    let yDomain: ClosedRange<Double>

    func path(in rect: CGRect) -> Path {
        var path = TrendLineShape(points: points, interval: interval, yDomain: yDomain).path(in: rect)
        guard let first = points.first, let last = points.last else { return path }
        let lastPoint = TrendGeometry.position(for: last, in: rect, interval: interval, yDomain: yDomain)
        let firstPoint = TrendGeometry.position(for: first, in: rect, interval: interval, yDomain: yDomain)
        path.addLine(to: CGPoint(x: lastPoint.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: firstPoint.x, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

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
                .stroke(Colormanager.Sleep.lavender.opacity(0.65), style: StrokeStyle(lineWidth: 3, lineCap: .round))

                Circle()
                    .fill(Colormanager.Sleep.lavender.opacity(0.35))
                    .frame(width: 11, height: 11)
                    .position(start)

                Circle()
                    .fill(Colormanager.Sleep.lavender)
                    .frame(width: 14, height: 14)
                    .position(current)

                Image(systemName: "flag.fill")
                    .foregroundStyle(Colormanager.Sleep.lavender)
                    .position(end)
            }
        }
    }
}
