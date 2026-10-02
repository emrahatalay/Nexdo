import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class PlanningViewModel {
    static let defaultAvailableMinutes = 360
    static let defaultBufferMinutes = 45
    static let dayStartHour = 9

    private let modelContext: ModelContext
    private let capacityService = CapacityService()
    private let planningService = PlanningService()
    private let routineScheduler = RoutineScheduler()

    let tomorrowDate: Date
    private(set) var dailyPlan: DailyPlan
    private(set) var inboxTasks: [TaskItem] = []
    private(set) var tomorrowTasks: [TaskItem] = []
    private(set) var activeRoutinesForTomorrow: [Routine] = []
    private(set) var capacityResult = CapacityResult(
        availableMinutes: 0, routineMinutes: 0, plannedTaskMinutes: 0, bufferMinutes: 0
    )
    private(set) var validationIssues: [PlanningValidationIssue] = []
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        self.tomorrowDate = Calendar.current.startOfDay(for: tomorrow)
        self.dailyPlan = Self.fetchOrCreateDailyPlan(for: tomorrowDate, in: modelContext)
        refresh()
    }

    private static func fetchOrCreateDailyPlan(for date: Date, in context: ModelContext) -> DailyPlan {
        let existingPlans = (try? context.fetch(FetchDescriptor<DailyPlan>())) ?? []
        if let existing = existingPlans.first(where: { $0.date == date }) {
            return existing
        }
        let plan = DailyPlan(date: date, availableFocusMinutes: defaultAvailableMinutes)
        plan.bufferMinutes = defaultBufferMinutes
        context.insert(plan)
        try? context.save()
        return plan
    }

    var blockingIssues: [PlanningValidationIssue] {
        validationIssues.filter(\.isBlocking)
    }

    /// Madde 11: timeline hem Task hem Routine gösterir. "Herhangi" zamanlı rutinler sabit bir
    /// saate iğnelenemediği için bu kronolojik görünüme dahil edilmez (Routines ekranında kalır).
    var timelineBlocks: [TimelineBlock] {
        var blocks: [TimelineBlock] = tomorrowTasks
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { task -> TimelineBlock? in
                guard let start = task.scheduledStart else { return nil }
                return TimelineBlock(
                    id: task.id,
                    startTime: start,
                    duration: task.estimatedDuration ?? 0,
                    title: task.title,
                    subtitle: task.firstAction,
                    kind: .task
                )
            }

        let routineBlocks = activeRoutinesForTomorrow.compactMap { routine -> TimelineBlock? in
            guard let anchor = anchorTime(for: routine) else { return nil }
            return TimelineBlock(
                id: routine.id,
                startTime: anchor,
                duration: routine.estimatedDuration,
                title: routine.title,
                subtitle: nil,
                kind: .routine
            )
        }
        blocks.append(contentsOf: routineBlocks)
        blocks.sort { $0.startTime < $1.startTime }

        if let last = blocks.last, dailyPlan.bufferMinutes > 0 {
            blocks.append(TimelineBlock(
                id: UUID(),
                startTime: last.startTime.addingTimeInterval(last.duration),
                duration: TimeInterval(dailyPlan.bufferMinutes * 60),
                title: "Tampon",
                subtitle: nil,
                kind: .buffer
            ))
        }
        return blocks
    }

    var capacityWarningMessage: String? {
        guard capacityResult.overCapacity else { return nil }
        let planned = capacityResult.plannedTaskMinutes + capacityResult.routineMinutes + capacityResult.bufferMinutes
        return "Yarın için \(Self.formatted(planned)) planladın ancak \(Self.formatted(capacityResult.availableMinutes)) kullanılabilir zaman belirledin."
    }

    func refresh() {
        let allTasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
        inboxTasks = allTasks
            .filter { ($0.status == .inbox || $0.status == .stopped) && $0.eisenhowerQuadrant == .unset }
            .sorted { $0.createdAt > $1.createdAt }
        tomorrowTasks = allTasks
            .filter { $0.status == .planned && $0.plannedDate == tomorrowDate }
            .sorted { $0.sortOrder < $1.sortOrder }

        let allRoutines = (try? modelContext.fetch(FetchDescriptor<Routine>())) ?? []
        activeRoutinesForTomorrow = routineScheduler.activeRoutines(from: allRoutines, on: tomorrowDate)

        recomputeSchedule()
        recomputeCapacity()
    }

    func classify(_ task: TaskItem, isImportant: Bool, isUrgent: Bool) {
        let quadrant = EisenhowerQuadrant.classify(isImportant: isImportant, isUrgent: isUrgent)
        task.eisenhowerQuadrant = quadrant
        task.updatedAt = .now

        if quadrant.isEligibleForTomorrow {
            task.status = .planned
            task.plannedDate = tomorrowDate
            task.sortOrder = (tomorrowTasks.map(\.sortOrder).max() ?? -1) + 1
        }

        save()
    }

    func setTimebox(_ task: TaskItem, minutes: Int) {
        task.estimatedDuration = TimeInterval(minutes * 60)
        task.updatedAt = .now
        save()
    }

    func setFirstAction(_ task: TaskItem, action: String) {
        task.firstAction = action.isEmpty ? nil : action
        task.updatedAt = .now
        save()
    }

    func removeFromTomorrow(_ task: TaskItem) {
        task.status = .inbox
        task.eisenhowerQuadrant = .unset
        task.plannedDate = nil
        task.scheduledStart = nil
        task.scheduledEnd = nil
        task.updatedAt = .now
        save()
    }

    /// `Array.move(fromOffsets:toOffset:)` SwiftUI'ye ait olduğundan ViewModel'i View
    /// framework'ünden ayrık tutmak için aynı semantik elle uygulanıyor.
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var reordered = tomorrowTasks
        let moving = source.map { reordered[$0] }
        for index in source.sorted(by: >) {
            reordered.remove(at: index)
        }
        let adjustedDestination = destination - source.filter { $0 < destination }.count
        reordered.insert(contentsOf: moving, at: adjustedDestination)

        for (index, task) in reordered.enumerated() {
            task.sortOrder = index
        }
        save()
    }

    func updateAvailableMinutes(_ minutes: Int) {
        dailyPlan.availableFocusMinutes = max(0, minutes)
        save()
    }

    func updateBufferMinutes(_ minutes: Int) {
        dailyPlan.bufferMinutes = max(0, minutes)
        save()
    }

    func lockPlan() {
        guard blockingIssues.isEmpty else { return }
        dailyPlan.plannedTaskMinutes = capacityResult.plannedTaskMinutes
        dailyPlan.routineMinutes = capacityResult.routineMinutes
        dailyPlan.isLocked = true
        dailyPlan.lockedAt = .now
        save()
    }

    func unlockPlan() {
        dailyPlan.isLocked = false
        dailyPlan.lockedAt = nil
        save()
    }

    private func recomputeCapacity() {
        let taskMinutes = tomorrowTasks.reduce(0) { $0 + Int(($1.estimatedDuration ?? 0) / 60) }
        let routineMinutes = activeRoutinesForTomorrow.reduce(0) { $0 + Int($1.estimatedDuration / 60) }
        capacityResult = capacityService.evaluate(
            availableMinutes: dailyPlan.availableFocusMinutes,
            routineMinutes: routineMinutes,
            plannedTaskMinutes: taskMinutes,
            bufferMinutes: dailyPlan.bufferMinutes
        )
        validationIssues = planningService.validate(tasks: tomorrowTasks, capacity: capacityResult)
    }

    private func recomputeSchedule() {
        let dayStart = Calendar.current.date(
            bySettingHour: Self.dayStartHour, minute: 0, second: 0, of: tomorrowDate
        ) ?? tomorrowDate
        let scheduled = planningService.scheduleSequentially(tasks: tomorrowTasks, dayStart: dayStart)
        for entry in scheduled {
            entry.task.scheduledStart = entry.start
            entry.task.scheduledEnd = entry.end
        }
    }

    /// `preferredStartTime` varsa onun saat/dakikası kullanılır; yoksa `timeOfDay`'den kaba bir
    /// varsayılan türetilir. "Anytime" rutinler için sabit bir saat anlamlı değildir, `nil` döner.
    private func anchorTime(for routine: Routine) -> Date? {
        let calendar = Calendar.current
        if let preferredStartTime = routine.preferredStartTime {
            let components = calendar.dateComponents([.hour, .minute], from: preferredStartTime)
            return calendar.date(
                bySettingHour: components.hour ?? 8,
                minute: components.minute ?? 0,
                second: 0,
                of: tomorrowDate
            )
        }
        switch routine.timeOfDay {
        case .morning:
            return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrowDate)
        case .afternoon:
            return calendar.date(bySettingHour: 13, minute: 0, second: 0, of: tomorrowDate)
        case .evening:
            return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: tomorrowDate)
        case .anytime:
            return nil
        }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    private static func formatted(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 { return "\(hours) saat \(mins) dakika" }
        if hours > 0 { return "\(hours) saat" }
        return "\(mins) dakika"
    }
}
