import CoreData
import XCTest
@testable import Sophros

@MainActor
final class CycleStoreTests: XCTestCase {
    private var persistence: PersistenceController!
    private var calendar: Calendar!

    override func setUp() {
        persistence = PersistenceController(inMemory: true)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testActionsShareOneNormalizedLogForTheSameDay() throws {
        let store = CycleStore(context: persistence.container.viewContext, calendar: calendar)
        let morning = date(2026, 4, 8, hour: 8)
        let evening = date(2026, 4, 8, hour: 21)

        try store.setSexType(.protected, on: morning)
        try store.togglePeriod(on: evening)
        try store.toggleSymptom("cramps", on: evening)

        let logs = try store.logs()
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.date, calendar.startOfDay(for: morning))
        XCTAssertTrue(logs.first?.isPeriodDay ?? false)
        XCTAssertEqual(logs.first?.sexTypeRaw, CycleSexType.protected.rawValue)
        XCTAssertEqual(logs.first?.symptoms?.count, 1)
    }

    func testSexCanChangeAndRemoveWithoutLeavingAnEmptyLog() throws {
        let store = CycleStore(context: persistence.container.viewContext, calendar: calendar)
        let day = date(2026, 4, 8)

        try store.setSexType(.protected, on: day)
        try store.setSexType(.unprotected, on: day)
        XCTAssertEqual((try store.logs()).first?.sexTypeRaw, CycleSexType.unprotected.rawValue)

        try store.setSexType(nil, on: day)
        XCTAssertTrue(try store.logs().isEmpty)
    }

    func testSeveralSymptomsAreSavedAndIndividuallyToggled() throws {
        let store = CycleStore(context: persistence.container.viewContext, calendar: calendar)
        let day = date(2026, 4, 8)

        try store.toggleSymptom("cramps", on: day)
        try store.toggleSymptom("fatigue", on: day)
        XCTAssertEqual((try store.status(for: day, referenceDate: day)).loggedSymptoms, ["cramps", "fatigue"])

        try store.toggleSymptom("cramps", on: day)
        XCTAssertEqual((try store.status(for: day, referenceDate: day)).loggedSymptoms, ["fatigue"])
    }

    func testPeriodImportIsIdempotentAndPreservesExistingSexLog() throws {
        let store = CycleStore(context: persistence.container.viewContext, calendar: calendar)
        let firstDay = date(2026, 4, 8)
        let secondDay = date(2026, 4, 9)

        try store.setSexType(.protected, on: firstDay)
        XCTAssertEqual(try store.importPeriodDays([firstDay, firstDay, secondDay]), 2)
        XCTAssertEqual(try store.importPeriodDays([firstDay, secondDay]), 0)

        let logs = try store.logs()
        XCTAssertEqual(logs.count, 2)
        XCTAssertTrue(logs.allSatisfy(\.isPeriodDay))
        XCTAssertEqual(
            logs.first(where: { log in
                log.date.map { calendar.isDate($0, inSameDayAs: firstDay) } ?? false
            })?.sexTypeRaw,
            CycleSexType.protected.rawValue
        )
    }

    func testSexImportUsesHealthProtectionValueAndPreservesLocalLog() throws {
        let store = CycleStore(context: persistence.container.viewContext, calendar: calendar)
        let protectedDay = date(2026, 4, 8)
        let unprotectedDay = date(2026, 4, 9)

        XCTAssertEqual(
            try store.importSexLogs([
                CycleSexImport(date: protectedDay, type: .protected),
                CycleSexImport(date: unprotectedDay, type: .unprotected)
            ]),
            2
        )
        XCTAssertEqual(try store.importSexLogs([
            CycleSexImport(date: protectedDay, type: .unprotected)
        ]), 0)

        let logs = try store.logs()
        XCTAssertEqual(
            logs.first(where: { log in
                log.date.map { calendar.isDate($0, inSameDayAs: protectedDay) } ?? false
            })?.sexTypeRaw,
            CycleSexType.protected.rawValue
        )
        XCTAssertEqual(
            logs.first(where: { log in
                log.date.map { calendar.isDate($0, inSameDayAs: unprotectedDay) } ?? false
            })?.sexTypeRaw,
            CycleSexType.unprotected.rawValue
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
