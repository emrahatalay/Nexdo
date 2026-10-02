import Foundation

/// Madde 26: "Son N görevde planladığın sürenin ortalama X katını kullandın." tarzı basit,
/// deterministik bir içgörü. Ağır bir ML sistemi kurulmuyor.
struct EstimationInsight {
    let sampleSize: Int
    let averageRatio: Double

    var summary: String? {
        guard sampleSize > 0 else { return nil }
        let percentage = Int((averageRatio * 100).rounded())
        return "Son \(sampleSize) görevde planladığın sürenin ortalama %\(percentage)'ini kullandın."
    }
}

/// Madde 27: Gün Sonu değerlendirmesinde gösterilen özet.
struct DayStatistics {
    let totalPlannedTasks: Int
    let completedCount: Int
    let stoppedCount: Int
    let plannedMinutes: Int
    let actualMinutes: Int
    let routineExpectedCount: Int
    let routineCompletedCount: Int
}

struct StatisticsService {
    /// Tamamlanmış ve hem tahmini hem gerçek süresi olan en güncel `recentLimit` görev üzerinden
    /// ortalama (gerçek / tahmini) oranını hesaplar.
    func estimationInsight(for tasks: [TaskItem], recentLimit: Int = 20) -> EstimationInsight {
        let eligible = tasks
            .filter { $0.status == .completed && ($0.estimatedDuration ?? 0) > 0 && $0.actualDuration > 0 }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .prefix(recentLimit)

        guard !eligible.isEmpty else {
            return EstimationInsight(sampleSize: 0, averageRatio: 0)
        }

        let ratios = eligible.map { $0.actualDuration / ($0.estimatedDuration ?? 1) }
        let average = ratios.reduce(0, +) / Double(ratios.count)
        return EstimationInsight(sampleSize: eligible.count, averageRatio: average)
    }

    /// `FocusSession` tarihi kaydı (`TaskItem`'in o anki durumu değil) günün gerçek verisidir —
    /// Madde 17'deki "durdurulan görev yeniden triyaj için inbox'a döner" kararı `plannedDate`'i
    /// temizlediğinden, günlük istatistikler `TaskItem.plannedDate` üzerinden güvenilir hesaplanamaz.
    func dayStatistics(
        for date: Date,
        allTasks: [TaskItem],
        allSessions: [FocusSession],
        allRoutines: [Routine],
        allCompletions: [RoutineCompletion],
        scheduler: RoutineScheduler,
        calendar: Calendar = .current
    ) -> DayStatistics {
        let daySessions = allSessions.filter { session in
            guard let ended = session.endedAt else { return false }
            return calendar.isDate(ended, inSameDayAs: date)
        }
        let completed = daySessions.filter { $0.state == .completed }
        let stopped = daySessions.filter { $0.state == .stopped }

        let stillPendingToday = allTasks.filter { task in
            (task.status == .planned || task.status == .active)
                && task.plannedDate.map { calendar.isDate($0, inSameDayAs: date) } == true
        }

        let plannedMinutes = daySessions.reduce(0) { $0 + Int($1.plannedDuration / 60) }
        let actualMinutes = daySessions.reduce(0) { $0 + Int($1.elapsedTime(at: $1.endedAt ?? .now) / 60) }

        let expectedRoutines = scheduler.activeRoutines(from: allRoutines, on: date, calendar: calendar)
        let completedRoutines = allCompletions.filter { calendar.isDate($0.date, inSameDayAs: date) }

        return DayStatistics(
            totalPlannedTasks: completed.count + stopped.count + stillPendingToday.count,
            completedCount: completed.count,
            stoppedCount: stopped.count,
            plannedMinutes: plannedMinutes,
            actualMinutes: actualMinutes,
            routineExpectedCount: expectedRoutines.count,
            routineCompletedCount: completedRoutines.count
        )
    }
}
