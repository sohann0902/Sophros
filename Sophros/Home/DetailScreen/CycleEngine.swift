//
//  CycleEngine.swift
//  Sophros
//

import Foundation

enum CyclePhase: String, CaseIterable, Identifiable {
    case period
    case follicular
    case ovulation
    case luteal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .period: "Menstrual Phase"
        case .follicular: "Follicular Phase"
        case .ovulation: "Ovulation Phase"
        case .luteal: "Luteal Phase"
        }
    }

    var information: String {
        switch self {
        case .period:
            "Your period is the start of a new cycle. Rest and log how you feel if it is helpful."
        case .follicular:
            "The follicular phase begins after your period starts and leads up to ovulation."
        case .ovulation:
            "Ovulation is estimated from your recent cycle history, so it is shown as a window rather than an exact day."
        case .luteal:
            "The luteal phase follows ovulation and continues until the next period begins."
        }
    }
}

enum CyclePeriodState: Equatable {
    case none
    case actual(day: Int)
    case predicted
}

struct CycleDateStatus: Identifiable, Equatable {
    let date: Date
    let periodState: CyclePeriodState
    let isFertileWindow: Bool
    let cycleDay: Int?
    let phase: CyclePhase?
    let calendarSubtitle: String?
    let loggedSymptoms: [String]

    var id: Date { date }

    var isActualPeriodDay: Bool {
        if case .actual = periodState { return true }
        return false
    }

    var isPredictedPeriodDay: Bool {
        periodState == .predicted
    }
}

/// An immutable representation of a saved cycle day. Core Data is converted to this
/// value by `CycleStore`, keeping all prediction logic deterministic and testable.
struct CycleLogSnapshot: Equatable {
    let date: Date
    let isPeriodDay: Bool
    let symptomKeys: [String]
}

/// The personal defaults saved in `CycleSettings` until there is enough history to learn from.
struct CycleSettingsSnapshot: Equatable {
    let cycleLength: Int
    let periodLength: Int

    static let `default` = CycleSettingsSnapshot(cycleLength: 28, periodLength: 5)
}

struct CycleSummary: Equatable {
    let lastPeriodStart: Date?
    let typicalCycleLength: Int
    let typicalPeriodLength: Int
    let cycleVariation: Int
}

/// Calculates all display states from immutable saved facts. It never writes data and
/// deliberately does not persist predictions: a new log instantly recalculates them.
struct CycleEngine {
    /// A prediction should communicate a short uncertainty window, not turn an
    /// irregular historical interval into several weeks of possible-period days.
    private static let maximumPredictionVariationDays = 3

    private let calendar: Calendar
    private let logsByDay: [Date: CycleLogSnapshot]
    private let periodRuns: [PeriodRun]
    private let summaryValue: CycleSummary
    private let predictedPeriodDaySet: Set<Date>

    init(
        logs: [CycleLogSnapshot],
        settings: CycleSettingsSnapshot,
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) {
        self.calendar = calendar

        var normalizedLogs: [Date: CycleLogSnapshot] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            normalizedLogs[day] = CycleLogSnapshot(
                date: day,
                isPeriodDay: log.isPeriodDay,
                symptomKeys: log.symptomKeys.sorted()
            )
        }
        logsByDay = normalizedLogs

        let runs = Self.makePeriodRuns(
            from: normalizedLogs.values,
            calendar: calendar
        )
        periodRuns = runs
        let calculatedSummary = Self.makeSummary(
            periodRuns: runs,
            settings: settings,
            calendar: calendar,
            referenceDate: referenceDate
        )
        summaryValue = calculatedSummary
        let nextPeriodPrediction = Self.makePredictedPeriodDays(
            summary: calculatedSummary,
            calendar: calendar
        )
        let remainingDaysOfLatestPeriod = Self.makeOpenPeriodContinuationDays(
            periodRuns: runs,
            typicalPeriodLength: calculatedSummary.typicalPeriodLength,
            calendar: calendar
        )
        predictedPeriodDaySet = nextPeriodPrediction.union(remainingDaysOfLatestPeriod)
    }

    var summary: CycleSummary { summaryValue }

    func status(for date: Date) -> CycleDateStatus {
        let day = calendar.startOfDay(for: date)
        let symptoms = logsByDay[day]?.symptomKeys ?? []

        if let actualDay = actualPeriodDayNumber(for: day) {
            return CycleDateStatus(
                date: day,
                periodState: .actual(day: actualDay),
                isFertileWindow: false,
                cycleDay: cycleDay(for: day),
                phase: .period,
                calendarSubtitle: "PERIOD · DAY \(actualDay)",
                loggedSymptoms: symptoms
            )
        }

        let calculatedCycleDay = cycleDay(for: day)
        let isPredictedPeriod = predictedPeriodDaySet.contains(day)
        let isFertile = !isPredictedPeriod && isFertileDay(for: calculatedCycleDay)
        let phase = phase(for: calculatedCycleDay)

        return CycleDateStatus(
            date: day,
            periodState: isPredictedPeriod ? .predicted : .none,
            isFertileWindow: isFertile,
            cycleDay: calculatedCycleDay,
            phase: phase,
            calendarSubtitle: subtitle(
                isPredictedPeriod: isPredictedPeriod,
                isFertile: isFertile
            ),
            loggedSymptoms: symptoms
        )
    }

    static func makePredictedPeriodDays(summary: CycleSummary, calendar: Calendar) -> Set<Date> {
        guard let lastPeriodStart = summary.lastPeriodStart else { return [] }

        let predictionVariation = min(
            max(summary.cycleVariation, 1),
            maximumPredictionVariationDays
        )

        let expectedStart = calendar.date(
            byAdding: .day,
            value: summary.typicalCycleLength,
            to: lastPeriodStart
        )!
        let earliestStart = calendar.date(
            byAdding: .day,
            value: -predictionVariation,
            to: expectedStart
        )!
        let latestEnd = calendar.date(
            byAdding: .day,
            value: predictionVariation + summary.typicalPeriodLength - 1,
            to: expectedStart
        )!

        return Set(Self.days(from: earliestStart, through: latestEnd, calendar: calendar))
    }

    /// A newly logged period start is a confirmed Day 1, but the remaining days are
    /// still only expected until the user logs them. This keeps the calendar honest:
    /// actual days are dark, while the likely remaining period days stay light.
    fileprivate static func makeOpenPeriodContinuationDays(
        periodRuns: [PeriodRun],
        typicalPeriodLength: Int,
        calendar: Calendar
    ) -> Set<Date> {
        guard let latestRun = periodRuns.last,
              latestRun.length < typicalPeriodLength,
              let expectedEnd = calendar.date(
                byAdding: .day,
                value: typicalPeriodLength - 1,
                to: latestRun.start
              ) else {
            return []
        }

        return Set(Self.days(from: latestRun.start, through: expectedEnd, calendar: calendar))
    }

    private func cycleDay(for date: Date) -> Int? {
        guard let cycleStart = periodRuns.last(where: { $0.start <= date })?.start else {
            return nil
        }

        return calendar.dateComponents([.day], from: cycleStart, to: date).day.map { $0 + 1 }
    }

    private func actualPeriodDayNumber(for date: Date) -> Int? {
        guard let run = periodRuns.first(where: { $0.days.contains(date) }) else {
            return nil
        }

        return calendar.dateComponents([.day], from: run.start, to: date).day.map { $0 + 1 }
    }

    private func phase(for cycleDay: Int?) -> CyclePhase? {
        guard let cycleDay else { return nil }

        if cycleDay <= summary.typicalPeriodLength { return .period }

        let ovulationDay = max(summary.typicalPeriodLength + 1, summary.typicalCycleLength - 14)
        if (ovulationDay - 1 ... ovulationDay + 1).contains(cycleDay) {
            return .ovulation
        }
        return cycleDay < ovulationDay ? .follicular : .luteal
    }

    private func isFertileDay(for cycleDay: Int?) -> Bool {
        guard let cycleDay else { return false }

        let ovulationDay = max(summary.typicalPeriodLength + 1, summary.typicalCycleLength - 14)
        return (ovulationDay - 3 ... ovulationDay + 1).contains(cycleDay)
    }

    private func subtitle(isPredictedPeriod: Bool, isFertile: Bool) -> String? {
        if isPredictedPeriod { return "POSSIBLE PERIOD DAY" }
        if isFertile { return "POSSIBLE FERTILE WINDOW" }
        return nil
    }
}

private extension CycleEngine {
    struct PeriodRun: Equatable {
        let days: [Date]

        var start: Date { days[0] }
        var end: Date { days[days.count - 1] }
        var length: Int { days.count }
    }

    static func makePeriodRuns(
        from logs: Dictionary<Date, CycleLogSnapshot>.Values,
        calendar: Calendar
    ) -> [PeriodRun] {
        let actualDays = logs
            .filter(\.isPeriodDay)
            .map(\.date)
            .sorted()

        guard !actualDays.isEmpty else { return [] }

        var runs: [[Date]] = [[actualDays[0]]]
        for day in actualDays.dropFirst() {
            let previous = runs[runs.count - 1][runs[runs.count - 1].count - 1]
            let expectedNextDay = calendar.date(byAdding: .day, value: 1, to: previous)!

            if calendar.isDate(day, inSameDayAs: expectedNextDay) {
                runs[runs.count - 1].append(day)
            } else {
                runs.append([day])
            }
        }

        return runs.map(PeriodRun.init(days:))
    }

    static func makeSummary(
        periodRuns: [PeriodRun],
        settings: CycleSettingsSnapshot,
        calendar: Calendar,
        referenceDate: Date
    ) -> CycleSummary {
        let fallbackCycleLength = max(settings.cycleLength, 1)
        let fallbackPeriodLength = max(settings.periodLength, 1)
        let cycleLengths = zip(periodRuns, periodRuns.dropFirst()).compactMap { previous, next in
            calendar.dateComponents([.day], from: previous.start, to: next.start).day
        }

        // A run containing today or yesterday may still be ongoing, so don't let its
        // incomplete duration distort the learned period length.
        let normalizedReference = calendar.startOfDay(for: referenceDate)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: normalizedReference)!
        let completedRuns = periodRuns.filter { run in
            run.end < yesterday
        }

        let learnedCycleLength = cycleLengths.count >= 3
            ? median(cycleLengths.suffix(6))
            : fallbackCycleLength
        let learnedPeriodLength = completedRuns.count >= 3
            ? median(completedRuns.suffix(6).map(\.length))
            : fallbackPeriodLength
        let variation = cycleLengths.count >= 3
            ? max(1, cycleLengths.suffix(6).map { abs($0 - learnedCycleLength) }.max() ?? 1)
            : 2

        return CycleSummary(
            lastPeriodStart: periodRuns.last?.start,
            typicalCycleLength: learnedCycleLength,
            typicalPeriodLength: learnedPeriodLength,
            cycleVariation: variation
        )
    }

    static func median<S: Sequence>(_ values: S) -> Int where S.Element == Int {
        let sortedValues = values.sorted()
        guard !sortedValues.isEmpty else { return 0 }
        return sortedValues[sortedValues.count / 2]
    }

    static func days(from start: Date, through end: Date, calendar: Calendar) -> [Date] {
        var days: [Date] = []
        var currentDay = calendar.startOfDay(for: start)
        let finalDay = calendar.startOfDay(for: end)

        while currentDay <= finalDay {
            days.append(currentDay)
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
        }
        return days
    }
}
