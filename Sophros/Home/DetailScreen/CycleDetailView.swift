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
    @AppStorage("hasSeenCycleOnboarding") private var hasSeenCycleOnboarding = false

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

                if !hasSeenCycleOnboarding {
                    FeatureOnboardingOverlay(
                        icon: "drop.fill",
                        tint: Colormanager.MenstrualCycle.mauve,
                        title: "Your cycle, in one place",
                        message: "Log period days and symptoms to see your cycle history and predicted phases. Your information stays on your device.",
                        content: { EmptyView() }
                    ) {
                        hasSeenCycleOnboarding = true
                    }
                }
            }
            .navigationTitle("Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                scrollPosition = selectedDate
                _ = try? store.settings()
                importHealthKitHistoryForTesting()
            }
            .sheet(isPresented: $showingPeriodOptions) {
                PeriodLogSheet(
                    date: selectedDate,
                isPeriodLogged: selectedStatus.isActualPeriodDay
                ) {
                    performCycleMutation {
                        _ = try store.togglePeriod(on: selectedDate)
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
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Colormanager.Typography.primaryText)
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
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Colormanager.MenstrualCycle.dustyRose)
                    
                    Text(selectedStatus.phase?.title ?? "Start tracking")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Colormanager.Typography.secondaryText)
                }
                Spacer(minLength: 8)
                Button { showingPhaseInfo = true } label: {
                    Image(systemName: "info")
                        .font(.subheadline.weight(.bold))
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
                        
//                        Image("flower")
//                            .renderingMode(.template)
//                            .resizable()
//                            .scaledToFit()
//                            .foregroundStyle(Colormanager.MenstrualCycle.blush)
//                            .offset(x: proxy.size.width / 1.5)
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
            Text("Symptoms").font(.headline.weight(.bold))
            if selectedStatus.loggedSymptoms.isEmpty {
                Text("Nothing logged for this day")
                    .font(.subheadline)
                    .foregroundStyle(Colormanager.Typography.secondaryText)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(selectedStatus.loggedSymptoms, id: \.self) { key in
                            SymptomPill(symptom: CycleSymptomOption.option(for: key))
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
            Text("Cycle summary").font(.headline.weight(.bold))
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
        selectedStatus.isFertileWindow ? Colormanager.MenstrualCycle.mauve : Colormanager.MenstrualCycle.dustyRose
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

private struct SexLogSheet: View {
    let date: Date
    let loggedType: CycleSexType?
    let onSelect: (CycleSexType?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Circle()
                    .fill(Colormanager.MenstrualCycle.mauve.opacity(0.18))
                    .frame(width: 58, height: 58)
                    .overlay {
                        Image(systemName: "heart.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Colormanager.MenstrualCycle.mauve)
                    }
                    .padding(.top, 10)
                
                Text("Log your sexual activity")
                    .font(.footnote)
                    .foregroundStyle(Colormanager.Typography.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 270)
                    .padding(.top, 12)
                
                HStack(spacing: 12) {
                SexLogChoice(
                    title: "Protected",
                    symbol: "shield.fill",
                    isSelected: loggedType == .protected
                ) { select(loggedType == .protected ? nil : .protected) }
                SexLogChoice(
                    title: "Unprotected",
                    symbol: "heart.fill",
                    isSelected: loggedType == .unprotected
                ) { select(loggedType == .unprotected ? nil : .unprotected) }
            }
            .padding(.top, 22)

            }
            .padding(.horizontal, 24)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    SheetCloseButton(action: dismiss.callAsFunction)
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }

    private func select(_ type: CycleSexType?) {
        onSelect(type)
        dismiss()
    }
}

private struct SexLogChoice: View {
    let title: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : Colormanager.Typography.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(isSelected ? Colormanager.MenstrualCycle.mauve : Colormanager.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.clear : Colormanager.MenstrualCycle.mauve.opacity(0.16), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PeriodLogSheet: View {
    let date: Date
    let isPeriodLogged: Bool
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Circle()
                    .fill(Colormanager.MenstrualCycle.dustyRose.opacity(0.72))
                    .frame(width: 58, height: 58)
                    .overlay {
                        Image(systemName: "drop.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Colormanager.MenstrualCycle.blush)
                    }
                    .padding(.top, 10)

                Text(isPeriodLogged
                     ? "This day is marked as a period day."
                     : "Mark selected date as a period day. You can log the remaining days as they happen.")
                .font(.footnote)
                .foregroundStyle(Colormanager.Typography.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 270)
                .padding(.top, 12)

                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Label(
                        isPeriodLogged ? "Remove period log" : "Log period",
                        systemImage: isPeriodLogged ? "trash" : "drop.fill"
                    )
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .foregroundStyle(isPeriodLogged ? Colormanager.MenstrualCycle.dustyRose : .white)
                .background(isPeriodLogged ? Colormanager.MenstrualCycle.blush.opacity(0.68) : Colormanager.MenstrualCycle.dustyRose)
                .clipShape(Capsule())
                .padding(.top, 22)

            }
            .padding(.horizontal, 24)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    SheetCloseButton(action: dismiss.callAsFunction)
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }
}

private struct SheetCloseButton: View {
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
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Colormanager.Typography.secondaryText)
                Text(date.formatted(.dateTime.day()))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(
                        status.isActualPeriodDay
                            ? .white
                            : (isToday ? Colormanager.MenstrualCycle.dustyRose : Colormanager.Typography.primaryText)
                    )
                    .frame(width: 42, height: 42)
                    .background(background)
                    .clipShape(Circle())
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(Colormanager.MenstrualCycle.dustyRose, lineWidth: 2)
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
        case .none: status.isFertileWindow ? Colormanager.MenstrualCycle.mauve.opacity(0.22) : Color.clear
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
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Colormanager.Typography.primaryText)
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
            Text(symptom.title).font(.subheadline.weight(.medium))
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
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Colormanager.MenstrualCycle.dustyRose)
                .frame(width: 36, height: 36)
                .background(Colormanager.MenstrualCycle.blush.opacity(0.5))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).foregroundStyle(Colormanager.Typography.secondaryText)
                Text(value).font(.headline.weight(.semibold))
            }
        }
    }
}

private struct PhaseInfoSheet: View {
    let phase: CyclePhase?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(phase?.title ?? "Your cycle").font(.title.bold())
                Text(phase?.information ?? "Log your period to begin seeing your cycle phase here.")
                    .foregroundStyle(Colormanager.Typography.secondaryText)
                Divider()
                Text("The four phases")
                    .font(.headline)
                ForEach(CyclePhase.allCases) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title).font(.subheadline.weight(.semibold))
                        Text(item.information)
                            .font(.footnote)
                            .foregroundStyle(Colormanager.Typography.secondaryText)
                    }
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("Cycle phase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done", action: dismiss.callAsFunction) } }
        }
        .presentationDetents([.medium])
    }
}

private struct SymptomPickerSheet: View {
    let date: Date
    @State private var selectedKeys: Set<String>
    let onToggle: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 10)]

    init(date: Date, selectedKeys: Set<String>, onToggle: @escaping (String) -> Void) {
        self.date = date
        _selectedKeys = State(initialValue: selectedKeys)
        self.onToggle = onToggle
    }

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Colormanager.MenstrualCycle.mauve.opacity(0.18))
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Colormanager.MenstrualCycle.mauve)
                }
                .padding(.top, 10)

            Text("Symptoms")
                .font(.title3.weight(.bold))
                .padding(.top, 14)
                .foregroundStyle(Colormanager.MenstrualCycle.mauve)

            Text("Choose everything that applies")
                .font(.footnote)
                .foregroundStyle(Colormanager.Typography.secondaryText)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(CycleSymptomOption.allCases) { symptom in
                        Button {
                            onToggle(symptom.key)
                            if selectedKeys.contains(symptom.key) {
                                selectedKeys.remove(symptom.key)
                            } else {
                                selectedKeys.insert(symptom.key)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(symptom.emoji)
                                Text(symptom.title).font(.subheadline.weight(.medium)).lineLimit(1)
                                Spacer(minLength: 0)
                                if selectedKeys.contains(symptom.key) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Colormanager.MenstrualCycle.mauve)
                                }
                            }
                            .padding(12)
                            .background(selectedKeys.contains(symptom.key) ? Colormanager.MenstrualCycle.mauve.opacity(0.16) : Colormanager.card)
                            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .stroke(selectedKeys.contains(symptom.key) ? Colormanager.MenstrualCycle.mauve.opacity(0.32) : .black.opacity(0.04), lineWidth: 1)
                            }
                        }
                        .foregroundStyle(Colormanager.Typography.primaryText)
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 12)
                }
                .padding(.top, 20)
            }
            .mask{
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.1),
                    .init(color: .black, location: 0.9),
                    .init(color: .clear, location: 0.0)
                ], startPoint: .top, endPoint: .bottom)
            }

            Button(action: dismiss.callAsFunction) {
                Text("Done")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Colormanager.MenstrualCycle.mauve)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
                .padding(.top, 14)
        }
        .padding(.horizontal, 24)
    }
}

private enum CycleSymptomOption: String, CaseIterable, Identifiable {
    case cramps, headache, fatigue, cravings, bloating, acne, backache, insomnia
    case tenderBreasts = "tender_breasts"
    case moodSwings = "mood_swings"

    var id: String { rawValue }
    var key: String { rawValue }

    var title: String {
        switch self {
        case .cramps: "Cramps"
        case .headache: "Headache"
        case .fatigue: "Fatigue"
        case .cravings: "Cravings"
        case .bloating: "Bloating"
        case .acne: "Acne"
        case .backache: "Backache"
        case .insomnia: "Insomnia"
        case .tenderBreasts: "Tender breasts"
        case .moodSwings: "Mood swings"
        }
    }

    var emoji: String {
        switch self {
        case .cramps: "😣"
        case .headache: "😖"
        case .fatigue: "😴"
        case .cravings: "🍫"
        case .bloating: "🎈"
        case .acne: "🫧"
        case .backache: "🌀"
        case .insomnia: "🌙"
        case .tenderBreasts: "💗"
        case .moodSwings: "🎭"
        }
    }

    static func option(for key: String) -> CycleSymptomOption {
        CycleSymptomOption(rawValue: key) ?? .cramps
    }
}

#Preview {
    NavigationStack { CycleDetailView(card: DashboardCard.otherCards.last!) }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
