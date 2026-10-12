import CoreData
import SwiftUI

struct CycleDetailView: View {
    let card: DashboardCard

    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CycleLog.date, ascending: true)], animation: nil)
    private var cycleLogs: FetchedResults<CycleLog>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CycleSettings.createdAt, ascending: true)], animation: nil)
    private var cycleSettings: FetchedResults<CycleSettings>

	@State private var selectedDate = Calendar.current.startOfDay(for: .now)
		@State private var scrollPosition: Date?
		@State private var showingSymptoms = false
		@State private var showingPhaseInfo = false
		@State private var showingSexOptions = false
		@State private var showingPeriodOptions = false
    @State private var scrollToTodayRequest = 0
    @State private var cycleDataRevision = 0
    @State private var hasStartedHealthKitImport = false
    @AppStorage("showCycleOnboarding") private var showCycleOnboarding = true

    private let calendar = Calendar.current

    private var store: CycleStore { CycleStore(context: context, calendar: calendar) }

    private var engine: CycleEngine {
        // A fetch request does not always invalidate this parent view when an
        // existing managed object's attributes change. Reading this revision
        // makes every saved cycle mutation immediately rebuild the derived UI.
        _ = cycleDataRevision
        let snapshots = cycleLogs.compactMap { log -> CycleLogSnapshot? in
            guard let date = log.date else { return nil }
            let symptoms = (log.symptoms as? Set<CycleSymptom>)?.compactMap(\.symptomKey).sorted() ?? []
            return CycleLogSnapshot(date: date, isPeriodDay: log.isPeriodDay, symptomKeys: symptoms)
        }
        let settings = cycleSettings.first
        return CycleEngine(
            logs: snapshots,
            settings: CycleSettingsSnapshot(
                cycleLength: Int(settings?.cycleLength ?? 28),
                periodLength: Int(settings?.periodLength ?? 5)
            ),
            calendar: calendar
        )
    }

    private var selectedStatus: CycleDateStatus { engine.status(for: selectedDate) }

    private var carouselDates: [Date] {
        let today = calendar.startOfDay(for: .now)
        let loggedDates = cycleLogs.compactMap(\.date)
        let oneYearBeforeToday = calendar.date(byAdding: .year, value: -1, to: today)!
        let oneYearAfterToday = calendar.date(byAdding: .year, value: 1, to: today)!

        let firstRelevantDate = min(loggedDates.min() ?? today, oneYearBeforeToday)
        let lastRelevantDate = max(loggedDates.max() ?? today, oneYearAfterToday)
        let startDate = calendar.date(byAdding: .day, value: -60, to: firstRelevantDate)!
        let endDate = calendar.date(byAdding: .day, value: 60, to: lastRelevantDate)!

        var dates: [Date] = []
        var date = calendar.startOfDay(for: startDate)
        while date <= endDate {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return dates
    }

    var body: some View {
            ZStack {
                Colormanager.baseBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        dateCarousel
                        phaseCard
                        logActions
                        symptomsCard
                        summaryCard
                    }
                    .padding(.bottom, 32)
                }
				
				FadeOverlay(isPresented: $showCycleOnboarding) {
					FeatureOnboardingOverlay(
						tint: Colormanager.MenstrualCycle.blush, background: Colormanager.MenstrualCycle.dustyRose,
						title: "Your cycle, in one place",
						message: "Log period days and symptoms to see your cycle history and predicted phases. Your information stays on your device.",
						content: { EmptyView() }
					) {
						showCycleOnboarding = false
						importHealthKitHistoryForTesting()
					}
                }
            }
            .navigationTitle("Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                scrollPosition = selectedDate
                // The engine already supplies default settings when none have
                // been saved, so an empty state does not need a Core Data write.
//                importHealthKitHistoryForTesting()
            }
            .sheet(isPresented: $showingPeriodOptions) {
                PeriodLogSheet(
                    date: selectedDate,
                isPeriodLogged: selectedStatus.isActualPeriodDay
                ) {
                    performCycleMutation {
                        _ = try store.togglePeriod(on: selectedDate)
						HapticManager.success()
                    }
                }
                .presentationDetents([.fraction(0.34)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(30)
                .presentationBackground(Colormanager.baseBackground)
            }
            .sheet(isPresented: $showingSexOptions) {
                SexLogSheet(date: selectedDate, loggedType: sexType(for: selectedDate)) { type in
                    performCycleMutation {
                        _ = try store.setSexType(type, on: selectedDate)
						HapticManager.success()
                    }
                }
                .presentationDetents([.fraction(0.34)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(30)
                .presentationBackground(Colormanager.baseBackground)
            }
            .sheet(isPresented: $showingSymptoms) {
                SymptomPickerSheet(date: selectedDate, selectedKeys: Set(selectedStatus.loggedSymptoms)) { key in
                    performCycleMutation {
                        _ = try store.toggleSymptom(key, on: selectedDate)
						HapticManager.selection()
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(30)
                .presentationBackground(Colormanager.baseBackground)
            }
			.sheet(isPresented: $showingPhaseInfo) { PhaseInfoSheet(phase: selectedStatus.phase) }
    }

    private var dateCarousel: some View {
        VStack(spacing: 8) {
            Button {
                scrollToTodayRequest += 1
            } label: {
                Text(selectedDate.relativeDisplayText)
					.fontStyle(.title)
                    .contentTransition(.interpolate)
                    .animation(.smooth(duration: 0.22, extraBounce: 0), value: selectedDate)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            GeometryReader { proxy in
                ScrollViewReader { scrollProxy in
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 12) {
                            ForEach(carouselDates, id: \.self) { date in
                                DateCarouselCell(
                                    date: date,
                                    status: engine.status(for: date),
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                    screenCenterX: proxy.frame(in: .global).midX
                                )
                                .id(date)
                                .onTapGesture {
                                    withAnimation(.smooth(duration: 0.42, extraBounce: 0)) {
                                        scrollPosition = date
                                    }
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollIndicators(.hidden)
                    .contentMargins(.horizontal, max(0, (proxy.size.width - 54) / 2), for: .scrollContent)
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $scrollPosition, anchor: .center)
                    .compositingGroup()
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.20),
                                .init(color: .black, location: 0.80),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                    .onAppear {
                        scrollPosition = selectedDate
                        DispatchQueue.main.async {
                                scrollProxy.scrollTo(selectedDate, anchor: .center)
                        }
                    }
                    .onChange(of: scrollToTodayRequest) { _, _ in
                        let today = calendar.startOfDay(for: .now)
						withAnimation(.smooth(duration: 0.55, extraBounce: 0)) {
                            scrollPosition = today
                        }
                    }
                    .onChange(of: scrollPosition) { _, newDate in
                        guard let newDate else { return }
						HapticManager.selection()
                        selectedDate = calendar.startOfDay(for: newDate)
                    }
                }
            }
            .frame(height: 104)
            .padding(.horizontal, 20)

            if let subtitle = selectedStatus.calendarSubtitle {
                Text(subtitle)
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(subtitleColor)
                    .frame(height: 16)
            } else {
                Color.clear.frame(height: 16)
            }
        }
    }

    private var phaseCard: some View {
        ZStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedStatus.cycleDay.map { "Day \($0)" } ?? "Your cycle")
                        .foregroundStyle(Colormanager.MenstrualCycle.dustyRose)
						.fontStyle(.largeTitle, size: 38)
                    
                    Text(selectedStatus.phase?.title ?? "Start tracking")
                        .foregroundStyle(Colormanager.Typography.secondaryText)
						.fontStyle(.headline)
                }
                Spacer(minLength: 8)
                Button { showingPhaseInfo = true } label: {
                    Image(systemName: "info")
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.78))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.black.opacity(0.12), lineWidth: 1))
                }
                .foregroundStyle(Colormanager.MenstrualCycle.dustyRose)
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
            .background(
                ZStack {
                    GeometryReader { proxy in
                        LinearGradient(colors: [
                            Colormanager.MenstrualCycle.blush.opacity(0.52),
                            
                            Colormanager.MenstrualCycle.blush.opacity(0.1),
                            
                            Colormanager.MenstrualCycle.blush.opacity(0.1),
                            
                            Colormanager.MenstrualCycle.blush.opacity(0.52)
                        ], startPoint: .top, endPoint: .bottom)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .padding(.horizontal, 20)
        }
    }

    private var logActions: some View {
        let loggedSexType = sexType(for: selectedDate)

        return HStack(spacing: 22) {
            CycleActionButton(
                title: selectedStatus.isActualPeriodDay ? "Period logged" : "Log period",
                symbol: selectedStatus.isActualPeriodDay ? "drop.fill" : "drop",
                tint: Colormanager.MenstrualCycle.dustyRose,
                filled: selectedStatus.isActualPeriodDay
            ) {
                showingPeriodOptions = true
            }
            CycleActionButton(title: "Symptoms", symbol: "plus", tint: Colormanager.MenstrualCycle.mauve, filled: false) {
                showingSymptoms = true
            }
            CycleActionButton(
                title: loggedSexType == nil ? "Sex" : "Sex logged",
                symbol: loggedSexType == nil ? "heart" : "heart.fill",
                tint: Colormanager.MenstrualCycle.dustyRose,
                filled: loggedSexType != nil
            ) {
                showingSexOptions = true
            }
        }
        .padding(.horizontal, 20)
    }

    private var symptomsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptoms")
				.fontStyle(.headline)
			
            if selectedStatus.loggedSymptoms.isEmpty {
                Text("Nothing logged for this day")
                    .foregroundStyle(Colormanager.Typography.secondaryText)
					.fontStyle(.subheadline)
				
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(selectedStatus.loggedSymptoms, id: \.self) { key in
                            SymptomPill(symptom: CycleSymptomOption.option(for: key))
								.onTapGesture {
									showingSymptoms = true
								}
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Colormanager.Typography.primaryText)
        .padding(16)
        .background(Colormanager.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.035), radius: 10, y: 4)
        .padding(.horizontal, 20)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Cycle summary")
				.fontStyle(.headline)
            CycleSummaryRow(icon: "calendar", title: "Last period", value: engine.summary.lastPeriodStart?.formatted(.dateTime.day().month(.abbreviated)) ?? "—")
            CycleSummaryRow(icon: "arrow.triangle.2.circlepath", title: "Typical cycle", value: "\(engine.summary.typicalCycleLength) days")
            CycleSummaryRow(icon: "drop", title: "Typical period", value: "\(engine.summary.typicalPeriodLength) days")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Colormanager.Typography.primaryText)
        .padding(22)
        .background(Colormanager.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 5)
        .padding(.horizontal, 20)
    }

    private var subtitleColor: Color {
        selectedStatus.isFertileWindow ? Colormanager.Water.skyBlue : Colormanager.MenstrualCycle.dustyRose
    }

    private func performCycleMutation(_ mutation: () throws -> Void) {
        do {
            try mutation()
            cycleDataRevision &+= 1
        } catch {
            assertionFailure("Could not save cycle data: \(error.localizedDescription)")
        }
    }

    private func importHealthKitHistoryForTesting() {
        guard !hasStartedHealthKitImport else { return }
        hasStartedHealthKitImport = true

        do {
            let store = CycleStore(context: context, calendar: calendar)
            guard try store.logs().isEmpty else {
                print("Skipped Apple Health cycle import because Sophros already has cycle logs.")
                return
            }
        } catch {
            print("Could not check existing cycle data before Apple Health import: \(error.localizedDescription)")
            return
        }

        Task {
            do {
                let importer = HealthKitCycleImporter(context: context, calendar: calendar)
                try await importer.requestReadAuthorization()
                let result = try await importer.importCycleHistory()
                cycleDataRevision &+= 1
                print("Imported \(result.newlyImportedDays) of \(result.healthKitDaysFound) period days and \(result.newlyImportedSexLogs) of \(result.healthKitSexualActivityDaysFound) sex logs from Apple Health.")
            } catch {
                print("Apple Health cycle import failed: \(error.localizedDescription)")
            }
        }
    }

    private func sexType(for date: Date) -> CycleSexType? {
        let day = calendar.startOfDay(for: date)
        let rawValue = cycleLogs.first(where: {
            guard let logDate = $0.date else { return false }
            return calendar.isDate(logDate, inSameDayAs: day)
        })?.sexTypeRaw
        return rawValue.flatMap(CycleSexType.init(rawValue:))
    }
}

struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Colormanager.MenstrualCycle.mauve)
                .frame(width: 38, height: 38)
                .background(Colormanager.card, in: .circle)
                .glassEffect()
        }
    }
}

private struct DateCarouselCell: View {
    let date: Date
    let status: CycleDateStatus
    let isSelected: Bool
    let screenCenterX: CGFloat

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        GeometryReader { proxy in
            let distance = abs(proxy.frame(in: .global).midX - screenCenterX)
            let scale = max(0.88, 1.12 - min(distance / 120, 1) * 0.86)

            VStack(spacing: 7) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
					.fontStyle(.lightBody)
				
                Text(date.formatted(.dateTime.day()))
					.foregroundStyle(
						status.isActualPeriodDay
							? .white
							: (isToday ? Colormanager.MenstrualCycle.dustyRose : Colormanager.Typography.primaryText)
					)
					.fontStyle(.headline)
                    .frame(width: 42, height: 42)
                    .background(background)
                    .clipShape(Circle())
                    .overlay {
                        if isSelected {
                            Circle()
								.stroke(status.isFertileWindow ? Colormanager.Water.skyBlue : Colormanager.MenstrualCycle.dustyRose, lineWidth: 2)
                                .frame(width: 50, height: 50)
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(scale)
        }
        .frame(width: 54)
    }

    @ViewBuilder private var background: some View {
        switch status.periodState {
        case .actual: Colormanager.MenstrualCycle.dustyRose
        case .predicted: Colormanager.MenstrualCycle.dustyRose.opacity(0.32)
		case .none: status.isFertileWindow ? Colormanager.Water.skyBlue.opacity(0.32) : Color.clear
        }
    }
}

private struct CycleActionButton: View {
    let title: String
    let symbol: String
    let tint: Color
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(filled ? .white : Colormanager.Typography.primaryText)
                    .frame(width: 62, height: 62)
                    .background(filled ? tint : Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                Text(title)
					.fontStyle(.body, size: 15)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct SymptomPill: View {
    let symptom: CycleSymptomOption

    var body: some View {
        HStack(spacing: 6) {
            Text(symptom.emoji)
            Text(symptom.title)
				.fontStyle(.subheadline)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Colormanager.MenstrualCycle.mauve.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct CycleSummaryRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Colormanager.MenstrualCycle.dustyRose)
                .frame(width: 36, height: 36)
                .background(Colormanager.MenstrualCycle.blush.opacity(0.5))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
					.fontStyle(.footer)
                Text(value)
					.fontStyle(.subheadline)
            }
        }
    }
}

#Preview {
    NavigationStack { CycleDetailView(card: DashboardCard.otherCards.last!) }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
