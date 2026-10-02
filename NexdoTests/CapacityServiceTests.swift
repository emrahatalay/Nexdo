import Testing
@testable import Nexdo

struct CapacityServiceTests {
    private let service = CapacityService()

    @Test func remainingMinutesWhenUnderCapacity() {
        let result = service.evaluate(availableMinutes: 360, routineMinutes: 60, plannedTaskMinutes: 200, bufferMinutes: 45)
        #expect(result.remainingMinutes == 55)
        #expect(result.overCapacity == false)
    }

    @Test func overCapacityWhenPlannedExceedsAvailable() {
        let result = service.evaluate(availableMinutes: 360, routineMinutes: 60, plannedTaskMinutes: 300, bufferMinutes: 45)
        #expect(result.remainingMinutes == -45)
        #expect(result.overCapacity == true)
    }

    @Test func exactFitIsNotOverCapacity() {
        let result = service.evaluate(availableMinutes: 100, routineMinutes: 0, plannedTaskMinutes: 100, bufferMinutes: 0)
        #expect(result.remainingMinutes == 0)
        #expect(result.overCapacity == false)
    }
}
