//
//  CycleStore.swift
//  Sophros
//

import CoreData

enum CycleSexType: String, CaseIterable, Identifiable {
    case protected
    case unprotected

    var id: String { rawValue }

    var title: String {
        switch self {
        case .protected: "Protected"
        case .unprotected: "Unprotected"
        }
    }
}

struct CycleSexImport: Equatable {
    let date: Date
    let type: CycleSexType
}

@MainActor
final class CycleStore {
    private let context: NSManagedObjectContext
    private var calendar: Calendar

    init(context: NSManagedObjectContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func settings() throws -> CycleSettings {
        let request = CycleSettings.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CycleSettings.createdAt, ascending: true)]

        if let savedSettings = try context.fetch(request).first {
            return savedSettings
        }

        let now = Date.now
        let settings = CycleSettings(context: context)
        settings.id = UUID()
        settings.cycleLength = 28
        settings.periodLength = 5
        settings.createdAt = now
        settings.updatedAt = now
        try save()
        return settings
    }

    func logs() throws -> [CycleLog] {
        let request = CycleLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CycleLog.date, ascending: true)]
        return try context.fetch(request)
    }

    func engine(referenceDate: Date = .now) throws -> CycleEngine {
        let savedSettings = try settings()
        let snapshots = try logs().compactMap(snapshot(for:))
        let settingsSnapshot = CycleSettingsSnapshot(
            cycleLength: Int(savedSettings.cycleLength),
            periodLength: Int(savedSettings.periodLength)
        )

        return CycleEngine(
            logs: snapshots,
            settings: settingsSnapshot,
            calendar: calendar,
            referenceDate: referenceDate
        )
    }

    @discardableResult
    func togglePeriod(on date: Date) throws -> CycleLog {
        let log = try upsertLog(on: date)
        log.isPeriodDay.toggle()
        log.updatedAt = .now
        try save()
        return log
    }

    /// Merges imported period days with local logs. Existing symptoms and sex logs
    /// are retained, and re-importing the same HealthKit history is a no-op.
    @discardableResult
    func importPeriodDays<S: Sequence>(_ dates: S) throws -> Int where S.Element == Date {
        let uniqueDays = Set(dates.map(normalizedDay))
        var importedCount = 0

        for day in uniqueDays {
            let log = try upsertLog(on: day)
            guard !log.isPeriodDay else { continue }

            log.isPeriodDay = true
            log.updatedAt = .now
            importedCount += 1
        }

        try save()
        return importedCount
    }

    /// Imports sexual activity only when the user has not already logged sex for
    /// that date. Local entries remain the source of truth after the one-time
    /// HealthKit import.
    @discardableResult
    func importSexLogs(_ entries: [CycleSexImport]) throws -> Int {
        var latestEntryByDay: [Date: CycleSexImport] = [:]
        for entry in entries {
            latestEntryByDay[normalizedDay(entry.date)] = entry
        }

        var importedCount = 0
        for (day, entry) in latestEntryByDay {
            let log = try upsertLog(on: day)
            guard log.sexTypeRaw == nil else { continue }

            log.sexTypeRaw = entry.type.rawValue
            log.updatedAt = .now
            importedCount += 1
        }

        try save()
        return importedCount
    }

    @discardableResult
    func setSexType(_ type: CycleSexType?, on date: Date) throws -> CycleLog? {
        if type == nil, try existingLog(on: date) == nil {
            return nil
        }

        let log = try upsertLog(on: date)
        log.sexTypeRaw = type?.rawValue
        log.updatedAt = .now
        deleteIfEmpty(log)
        try save()
        return log.isDeleted ? nil : log
    }

    @discardableResult
    func toggleSymptom(_ symptomKey: String, on date: Date) throws -> CycleLog {
        let normalizedKey = symptomKey.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!normalizedKey.isEmpty, "A symptom key must not be empty.")

        let log = try upsertLog(on: date)
        let request = CycleSymptom.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "log == %@ AND symptomKey == %@",
            log,
            normalizedKey
        )

        if let existingSymptom = try context.fetch(request).first {
            context.delete(existingSymptom)
        } else {
            let symptom = CycleSymptom(context: context)
            symptom.id = UUID()
            symptom.symptomKey = normalizedKey
            symptom.createdAt = .now
            symptom.updatedAt = .now
            symptom.log = log
        }

        log.updatedAt = .now
        deleteIfEmpty(log)
        try save()
        return log
    }

    func status(for date: Date, referenceDate: Date = .now) throws -> CycleDateStatus {
        try engine(referenceDate: referenceDate).status(for: normalizedDay(date))
    }

    func normalizedDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
}

private extension CycleStore {
    func existingLog(on date: Date) throws -> CycleLog? {
        let request = CycleLog.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "date == %@", normalizedDay(date) as NSDate)
        return try context.fetch(request).first
    }

    func upsertLog(on date: Date) throws -> CycleLog {
        let normalizedDate = normalizedDay(date)
        if let existingLog = try existingLog(on: normalizedDate) {
            return existingLog
        }

        let now = Date.now
        let log = CycleLog(context: context)
        log.id = UUID()
        log.date = normalizedDate
        log.isPeriodDay = false
        log.createdAt = now
        log.updatedAt = now
        return log
    }

    func snapshot(for log: CycleLog) -> CycleLogSnapshot? {
        guard let date = log.date else { return nil }

        let symptoms = (log.symptoms as? Set<CycleSymptom>)?
            .compactMap(\.symptomKey)
            .sorted() ?? []

        return CycleLogSnapshot(
            date: date,
            isPeriodDay: log.isPeriodDay,
            symptomKeys: symptoms
        )
    }

    func deleteIfEmpty(_ log: CycleLog) {
        let hasSymptoms = (log.symptoms?.count ?? 0) > 0
        let hasSex = log.sexTypeRaw != nil

        if !log.isPeriodDay && !hasSex && !hasSymptoms {
            context.delete(log)
        }
    }

    func save() throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}
