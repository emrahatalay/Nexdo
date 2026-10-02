import Foundation

struct CapacityResult: Equatable {
    let availableMinutes: Int
    let routineMinutes: Int
    let plannedTaskMinutes: Int
    let bufferMinutes: Int

    var remainingMinutes: Int {
        availableMinutes - routineMinutes - plannedTaskMinutes - bufferMinutes
    }

    var overCapacity: Bool {
        remainingMinutes < 0
    }
}

/// Madde 36: available - routines - tasks - buffer = remaining.
struct CapacityService {
    func evaluate(
        availableMinutes: Int,
        routineMinutes: Int,
        plannedTaskMinutes: Int,
        bufferMinutes: Int
    ) -> CapacityResult {
        CapacityResult(
            availableMinutes: availableMinutes,
            routineMinutes: routineMinutes,
            plannedTaskMinutes: plannedTaskMinutes,
            bufferMinutes: bufferMinutes
        )
    }
}
