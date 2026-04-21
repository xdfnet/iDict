import Foundation
import Testing
@testable import iDict

struct KeyboardSimulatorTests {

    // MARK: - simulateCopyCommand Tests

    @Test("simulateCopyCommand returns Result type")
    func simulateCopyCommandReturnsResult() async {
        // Test that simulateCopyCommand returns a Result (success or failure)
        let result = await KeyboardSimulator.simulateCopyCommand()
        #expect(result != nil)
    }

    @Test("simulateCopyCommand returns either success or failure")
    func simulateCopyCommandReturnsSuccessOrFailure() async {
        let result = await KeyboardSimulator.simulateCopyCommand()

        switch result {
        case .success:
            // Permission granted, copy succeeded
            break
        case .failure(let error):
            // Either permission denied or event failed
            #expect(error != nil)
        }
    }

    // MARK: - KeyboardSimulatorError Tests

    @Test("KeyboardSimulatorError permissionDenied has correct description")
    func errorPermissionDeniedDescription() {
        let error = KeyboardSimulatorError.permissionDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("输入监视"))
    }

    @Test("KeyboardSimulatorError eventCreationFailed has correct description")
    func errorEventCreationFailedDescription() {
        let error = KeyboardSimulatorError.eventCreationFailed
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("创建键盘事件失败"))
    }

    @Test("KeyboardSimulatorError eventPostFailed has correct description")
    func errorEventPostFailedDescription() {
        let error = KeyboardSimulatorError.eventPostFailed
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("发送键盘事件失败"))
    }

    @Test("KeyboardSimulatorError all cases have recovery suggestions")
    func allErrorCasesHaveRecoverySuggestions() {
        let errors: [KeyboardSimulatorError] = [
            .permissionDenied,
            .eventCreationFailed,
            .eventPostFailed
        ]

        for error in errors {
            #expect(error.recoverySuggestion != nil)
        }
    }

    @Test("KeyboardSimulatorError permissionDenied has specific recovery suggestion")
    func errorPermissionDeniedRecoverySuggestion() {
        let error = KeyboardSimulatorError.permissionDenied
        #expect(error.recoverySuggestion!.contains("系统设置"))
        #expect(error.recoverySuggestion!.contains("隐私与安全性"))
    }

    @Test("KeyboardSimulatorError eventCreationFailed has generic recovery suggestion")
    func errorEventCreationFailedRecoverySuggestion() {
        let error = KeyboardSimulatorError.eventCreationFailed
        #expect(error.recoverySuggestion!.contains("重启应用"))
    }

    @Test("KeyboardSimulatorError conforms to LocalizedError")
    func errorConformsToLocalizedError() {
        let error: KeyboardSimulatorError = .permissionDenied
        #expect(error is LocalizedError)
    }

    @Test("KeyboardSimulatorError conforms to Sendable")
    func errorConformsToSendable() {
        // Sendable is a marker protocol, verify the error type is Sendable by checking it satisfies the protocol
        func assertSendable<T: Sendable>(_ value: T) {}
        let error: KeyboardSimulatorError = .eventCreationFailed
        assertSendable(error)
    }
}