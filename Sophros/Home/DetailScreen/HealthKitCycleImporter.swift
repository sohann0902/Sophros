//
//  HealthKitCycleImporter.swift
//  Sophros
//

import CoreData
import Foundation
import HealthKit

struct CycleHealthImportResult: Equatable {
    let healthKitDaysFound: Int
    let newlyImportedDays: Int
    let healthKitSexualActivityDaysFound: Int
    let newlyImportedSexLogs: Int
}

enum CycleHealthImportError: LocalizedError {
    case healthDataUnavailable
    case existingCycleData

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            "Apple Health data is unavailable on this device."
        case .existingCycleData:
            "Your existing cycle data was kept. Apple Health import is only available during initial setup."
        }
    }
}

/// Imports menstrual-flow and sexual-activity history. It deliberately does not
/// write to Apple Health and it never removes local logs if a Health sample is deleted.
@MainActor
final class HealthKitCycleImporter {
    private let healthStore: HKHealthStore
    private let context: NSManagedObjectContext
    private let calendar: Calendar
    private let menstrualFlowType: HKCategoryType
    private let sexualActivityType: HKCategoryType

    init(
        context: NSManagedObjectContext,
        healthStore: HKHealthStore = HKHealthStore(),
        calendar: Calendar = .current
    ) {
        self.context = context
        self.healthStore = healthStore
        self.calendar = calendar
        self.menstrualFlowType = HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
        self.sexualActivityType = HKObjectType.categoryType(forIdentifier: .sexualActivity)!
    }

    func requestReadAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw CycleHealthImportError.healthDataUnavailable
        }

        try await healthStore.requestAuthorization(
            toShare: [],
            read: [menstrualFlowType, sexualActivityType]
        )
    }

    func importCycleHistory() async throws -> CycleHealthImportResult {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw CycleHealthImportError.healthDataUnavailable
        }

        // An import establishes the user's baseline history. Combining it with
        // already logged in-app days can produce an artificial cycle pattern,
        // so subsequent imports must be a deliberate replace/merge workflow.
        let store = CycleStore(context: context, calendar: calendar)
        guard try store.logs().isEmpty else {
            throw CycleHealthImportError.existingCycleData
        }

        async let menstrualFlowSamples = categorySamples(for: menstrualFlowType)
        async let sexualActivitySamples = categorySamples(for: sexualActivityType)

        let (flowSamples, activitySamples) = try await (menstrualFlowSamples, sexualActivitySamples)
        let periodDays = Set(flowSamples.flatMap(periodDays(from:)))
        let sexEntries = activitySamples.compactMap(sexEntry(from:))
        let importedPeriodCount = try store
            .importPeriodDays(periodDays)
        let importedSexCount = try store.importSexLogs(sexEntries)

        return CycleHealthImportResult(
            healthKitDaysFound: periodDays.count,
            newlyImportedDays: importedPeriodCount,
            healthKitSexualActivityDaysFound: sexEntries.count,
            newlyImportedSexLogs: importedSexCount
        )
    }

    private func categorySamples(for type: HKCategoryType) async throws -> [HKCategorySample] {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }

            healthStore.execute(query)
        }
    }

    private func sexEntry(from sample: HKCategorySample) -> CycleSexImport? {
        guard let protectionUsed = sample.metadata?[HKMetadataKeySexualActivityProtectionUsed] as? Bool else {
            return nil
        }

        return CycleSexImport(
            date: sample.startDate,
            type: protectionUsed ? .protected : .unprotected
        )
    }

    private func periodDays(from sample: HKCategorySample) -> [Date] {
        // HealthKit can also contain an explicit “no flow” sample for a day.
        // It belongs to the same category type, but it must never become a
        // logged period day in Sophros.
        guard sample.value != HKCategoryValueMenstrualFlow.none.rawValue else {
            return []
        }

        let start = calendar.startOfDay(for: sample.startDate)
        let end = inclusiveEndDay(for: sample)
        guard start <= end else { return [] }

        var days: [Date] = []
        var day = start
        while day <= end {
            days.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        return days
    }

    /// HealthKit samples that finish exactly at midnight use that time as the end
    /// boundary, not an additional period day.
    private func inclusiveEndDay(for sample: HKCategorySample) -> Date {
        let start = calendar.startOfDay(for: sample.startDate)
        let end = calendar.startOfDay(for: sample.endDate)

        guard sample.endDate > sample.startDate,
              calendar.isDate(sample.endDate, equalTo: end, toGranularity: .minute),
              sample.endDate == end else {
            return end
        }

        return max(start, calendar.date(byAdding: .day, value: -1, to: end)!)
    }
}
