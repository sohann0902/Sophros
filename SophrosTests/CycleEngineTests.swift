import XCTest
@testable import Sophros

final class CycleEngineTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testNoCycleHistoryHasNoDerivedCycleState() {
        let engine = makeEngine(logs: [], referenceDate: date(2026, 4, 1))

        let status = engine.status(for: date(2026, 4, 1))

        XCTAssertEqual(status.periodState, .none)
        XCTAssertNil(status.cycleDay)
        XCTAssertNil(status.phase)
        XCTAssertNil(status.calendarSubtitle)
    }

    func testFirstLoggedPeriodIsActualAndContinuesAsExpectedDays() {
        let engine = makeEngine(
            logs: period(start: date(2026, 4, 10), length: 1),
            referenceDate: date(2026, 4, 10)
        )

        XCTAssertEqual(engine.status(for: date(2026, 4, 10)).periodState, .actual(day: 1))
        XCTAssertEqual(engine.status(for: date(2026, 4, 11)).periodState, .predicted)
        XCTAssertEqual(engine.status(for: date(2026, 4, 11)).cycleDay, 2)
    }

    func testRegular28DayHistoryLearnsCycleAndPredictsRange() {
        let logs = period(start: date(2026, 1, 1))
            + period(start: date(2026, 1, 29))
            + period(start: date(2026, 2, 26))
            + period(start: date(2026, 3, 26))
        let engine = makeEngine(logs: logs, referenceDate: date(2026, 4, 5))

        XCTAssertEqual(engine.summary.typicalCycleLength, 28)
        XCTAssertEqual(engine.summary.typicalPeriodLength, 4)
        XCTAssertEqual(engine.status(for: date(2026, 4, 22)).periodState, .predicted)
        XCTAssertEqual(engine.status(for: date(2026, 4, 22)).calendarSubtitle, "POSSIBLE PERIOD DAY")
    }

    func testThirtyAndThirtyOneDayHistoryLearnsMedianCycleLength() {
        let logs = period(start: date(2026, 1, 1), length: 5)
            + period(start: date(2026, 2, 1), length: 5)
            + period(start: date(2026, 3, 3), length: 5)
            + period(start: date(2026, 4, 3), length: 5)
        let engine = makeEngine(logs: logs, referenceDate: date(2026, 4, 12))

        XCTAssertEqual(engine.summary.typicalCycleLength, 31)
        XCTAssertEqual(engine.summary.typicalPeriodLength, 5)
        XCTAssertEqual(engine.status(for: date(2026, 5, 3)).periodState, .predicted)
    }

    func testLargeHistoricalVarianceDoesNotCreateWeeksOfPossiblePeriodDays() {
        let summary = CycleSummary(
            lastPeriodStart: date(2026, 4, 1),
            typicalCycleLength: 30,
            typicalPeriodLength: 5,
            cycleVariation: 24
        )

        let predictedDays = CycleEngine.makePredictedPeriodDays(summary: summary, calendar: calendar)

        // Three days on either side of the expected start, plus five expected
        // period days: a concise 11-day uncertainty window rather than 53 days.
        XCTAssertEqual(predictedDays.count, 11)
        XCTAssertTrue(predictedDays.contains(date(2026, 4, 28)))
        XCTAssertTrue(predictedDays.contains(date(2026, 5, 8)))
        XCTAssertFalse(predictedDays.contains(date(2026, 5, 9)))
    }

    func testActualPeriodInsidePredictionReplacesPastRangeAndKeepsFutureDaysExpected() {
        let historicalLogs = period(start: date(2026, 1, 1))
            + period(start: date(2026, 1, 29))
            + period(start: date(2026, 2, 26))
            + period(start: date(2026, 3, 26))
        let engine = makeEngine(
            logs: historicalLogs + period(start: date(2026, 4, 23), length: 1),
            referenceDate: date(2026, 4, 23)
        )

        XCTAssertEqual(engine.status(for: date(2026, 4, 22)).periodState, .none)
        XCTAssertEqual(engine.status(for: date(2026, 4, 23)).periodState, .actual(day: 1))
        XCTAssertEqual(engine.status(for: date(2026, 4, 24)).periodState, .predicted)
    }

    func testBackdatedSymptomsStayOnTheirLoggedDate() {
        let symptomDate = date(2026, 3, 8)
        let engine = makeEngine(
            logs: [CycleLogSnapshot(date: symptomDate, isPeriodDay: false, symptomKeys: ["fatigue", "cramps"])],
            referenceDate: date(2026, 4, 1)
        )

        XCTAssertEqual(engine.status(for: symptomDate).loggedSymptoms, ["cramps", "fatigue"])
        XCTAssertTrue(engine.status(for: date(2026, 3, 9)).loggedSymptoms.isEmpty)
    }

    func testFertileWindowIsEstimatedFromTheCycleDay() {
        let engine = makeEngine(
            logs: period(start: date(2026, 3, 25)),
            referenceDate: date(2026, 4, 5)
        )

        let status = engine.status(for: date(2026, 4, 5))
        XCTAssertEqual(status.cycleDay, 12)
        XCTAssertTrue(status.isFertileWindow)
        XCTAssertEqual(status.phase, .follicular)
    }

    private func makeEngine(
        logs: [CycleLogSnapshot],
        settings: CycleSettingsSnapshot = .init(cycleLength: 28, periodLength: 4),
        referenceDate: Date
    ) -> CycleEngine {
        CycleEngine(logs: logs, settings: settings, calendar: calendar, referenceDate: referenceDate)
    }

    private func period(start: Date, length: Int = 4) -> [CycleLogSnapshot] {
        (0..<length).map { offset in
            CycleLogSnapshot(
                date: calendar.date(byAdding: .day, value: offset, to: start)!,
                isPeriodDay: true,
                symptomKeys: []
            )
        }
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
