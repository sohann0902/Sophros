//
//  Persistence.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let newItem = UserProfile(context: viewContext)
        newItem.id = UUID()
        newItem.createdAt = .now
        newItem.displayName = "Sohann"
        newItem.userType = "paid"
        
        for i in 0..<3 {
            let waterEntry = WaterEntry(context: viewContext)
            waterEntry.amountML = 250
            waterEntry.createdAt = .now
            waterEntry.id = UUID()
            waterEntry.source = .preset
            waterEntry.note = "test"
            waterEntry.updatedAt = .now
        }
        
        let goal = WaterGoal(context: viewContext)
        goal.amountML = 10000
        goal.id = UUID()
        goal.createdAt = .now
        goal.updatedAt = .now

        let reminder1 = Reminder(context: viewContext)
        reminder1.id = UUID()
        reminder1.title = "Drink 2.5L Water"
        reminder1.dueAt = Calendar.current.date(byAdding: .hour, value: 2, to: .now)
        reminder1.sortOrder = 0
        reminder1.createdAt = .now
        reminder1.updatedAt = .now

        let reminder2 = Reminder(context: viewContext)
        reminder2.id = UUID()
        reminder2.title = "Read 20 pages"
        reminder2.sortOrder = 1
        reminder2.createdAt = .now
        reminder2.updatedAt = .now

        let reminder3 = Reminder(context: viewContext)
        reminder3.id = UUID()
        reminder3.title = "Buy groceries"
        reminder3.completedAt = .now
        reminder3.sortOrder = 0
        reminder3.createdAt = .now
        reminder3.updatedAt = .now
        
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)!.start

        func workoutDate(
            dayOffset: Int,
            hour: Int,
            minute: Int = 0
        ) -> Date {
            let day = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: weekStart
            )!

            return calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: day
            )!
        }

        // Monday: Push Day
        let pushDay = WorkoutSession(context: viewContext)
        pushDay.id = UUID()
        pushDay.title = "Push Day"
        pushDay.note = "Chest, shoulders and triceps"
        pushDay.createdAt = .now
        pushDay.startedAt = workoutDate(dayOffset: 0, hour: 18)
        pushDay.completedAt = workoutDate(dayOffset: 0, hour: 19, minute: 10)

        let benchPress = WorkoutEntry(context: viewContext)
        benchPress.id = UUID()
        benchPress.createdAt = .now
        benchPress.name = "Bench Press"
        benchPress.sets = 3
        benchPress.reps = 10
        benchPress.weight = 60
        benchPress.session = pushDay

        let shoulderPress = WorkoutEntry(context: viewContext)
        shoulderPress.id = UUID()
        shoulderPress.createdAt = .now
        shoulderPress.name = "Shoulder Press"
        shoulderPress.sets = 3
        shoulderPress.reps = 12
        shoulderPress.weight = 15
        shoulderPress.session = pushDay

        let tricepPushdown = WorkoutEntry(context: viewContext)
        tricepPushdown.id = UUID()
        tricepPushdown.createdAt = .now
        tricepPushdown.name = "Tricep Pushdown"
        tricepPushdown.sets = 3
        tricepPushdown.reps = 12
        tricepPushdown.weight = 25
        tricepPushdown.session = pushDay

        // Wednesday: Pull Day
        let pullDay = WorkoutSession(context: viewContext)
        pullDay.id = UUID()
        pullDay.title = "Pull Day"
        pullDay.note = "Back and biceps"
        pullDay.createdAt = .now
        pullDay.startedAt = workoutDate(dayOffset: 2, hour: 18, minute: 15)
        pullDay.completedAt = workoutDate(dayOffset: 2, hour: 19, minute: 20)

        let latPulldown = WorkoutEntry(context: viewContext)
        latPulldown.id = UUID()
        latPulldown.createdAt = .now
        latPulldown.name = "Lat Pulldown"
        latPulldown.sets = 3
        latPulldown.reps = 12
        latPulldown.weight = 45
        latPulldown.session = pullDay

        let seatedRow = WorkoutEntry(context: viewContext)
        seatedRow.id = UUID()
        seatedRow.createdAt = .now
        seatedRow.name = "Seated Row"
        seatedRow.sets = 3
        seatedRow.reps = 10
        seatedRow.weight = 40
        seatedRow.session = pullDay

        let bicepCurl = WorkoutEntry(context: viewContext)
        bicepCurl.id = UUID()
        bicepCurl.createdAt = .now
        bicepCurl.name = "Bicep Curl"
        bicepCurl.sets = 3
        bicepCurl.reps = 12
        bicepCurl.weight = 12.5
        bicepCurl.session = pullDay
        
        let t = WorkoutTemplate(context: viewContext)
        t.title = "Leg day"
        t.createdAt = .now
        t.id = UUID()
        
        let t1 = WorkoutTemplate(context: viewContext)
        t1.title = "Push day"
        t1.createdAt = .now
        t1.id = UUID()
        
        let t2 = WorkoutTemplate(context: viewContext)
        t2.title = "Pull day"
        t2.createdAt = .now
        t2.id = UUID()
        
        let e1 = WorkoutTemplateEntry(context: viewContext)
        e1.createdAt = .now
        e1.id = UUID()
        e1.name = "squats"
        e1.reps = 10
        e1.sets = 3
        e1.template = t
        
        let e2 = WorkoutTemplateEntry(context: viewContext)
        e2.createdAt = .now
        e2.id = UUID()
        e2.name = "chest press"
        e2.reps = 10
        e2.sets = 3
        e2.template = t1
        
        let e3 = WorkoutTemplateEntry(context: viewContext)
        e3.createdAt = .now
        e3.id = UUID()
        e3.name = "lat pulldown"
        e3.reps = 10
        e3.sets = 3
        e3.template = t2
        
        let m1 = MealLog(context: viewContext)
        m1.title = "breakfast"
        m1.createdAt = .now
        m1.id = UUID()
        m1.mealType = .breakfast
        m1.kindRaw = "log"
        m1.occuredAt = .now
        
        let m2 = MealLog(context: viewContext)
        m2.title = "Lunch"
        m2.createdAt = .now
        m2.id = UUID()
        m2.mealType = .lunch
        m2.kindRaw = "log"
        m2.occuredAt = .now
        
        let m3 = MealLog(context: viewContext)
        m3.title = "Dinner"
        m3.createdAt = .now
        m3.id = UUID()
        m3.mealType = .dinner
        m3.kindRaw = "log"
        m3.occuredAt = .now
        
        let m4 = MealLog(context: viewContext)
        m4.title = "Snack"
        m4.createdAt = .now
        m4.id = UUID()
        m4.mealType = .snack
        m4.kindRaw = "log"
        m4.occuredAt = .now
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Sophros")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            
            guard let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.Sophros.com"
            ) else {
                fatalError("Unable to locate App Group container")
            }

            let storeURL = groupURL.appendingPathComponent("Sophros.sqlite")

            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true

            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
