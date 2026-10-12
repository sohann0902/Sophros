//
//  WeightTrendSection.swift
//  Sophros
//
//  Created by Sohan Maurya on 26/09/26.
//

import SwiftUI
import CoreData

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
				ContentUnavailableView {
					Label {
						Text("No weight entries yet")
							.fontStyle(.headline)
					} icon: {
						Image(systemName: "scalemass")
							.font(.system(size: 32))
					}
				} description: {
					Text("Log a weight to see your progress here.")
						.fontStyle(.body)
				}
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
                    .stroke(Colormanager.Calendar.green, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                ForEach(points) { point in
                    ZStack {
                        Circle()
                            .fill(Colormanager.Calendar.green)
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
