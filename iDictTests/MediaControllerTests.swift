import Foundation
import Testing
@testable import iDict

struct MediaControllerTests {

    // MARK: - MediaControllerError Tests

    @Test("MediaControllerError permissionDenied has correct description")
    func mediaControllerErrorPermissionDeniedDescription() {
        let error = MediaControllerError.permissionDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("辅助功能"))
    }

    @Test("MediaControllerError eventCreationFailed has correct description")
    func mediaControllerErrorEventCreationFailedDescription() {
        let error = MediaControllerError.eventCreationFailed
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("创建"))
    }

    @Test("MediaControllerError eventPostFailed has correct description")
    func mediaControllerErrorEventPostFailedDescription() {
        let error = MediaControllerError.eventPostFailed
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("发送"))
    }

    @Test("MediaControllerError all cases have error descriptions")
    func allMediaControllerErrorCasesHaveDescriptions() {
        let errors: [MediaControllerError] = [
            .permissionDenied,
            .eventCreationFailed,
            .eventPostFailed
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("MediaControllerError permissionDenied has recovery suggestion")
    func mediaControllerErrorPermissionDeniedHasRecoverySuggestion() {
        let error = MediaControllerError.permissionDenied
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion!.contains("系统设置"))
    }

    @Test("MediaControllerError eventCreationFailed has recovery suggestion")
    func mediaControllerErrorEventCreationFailedHasRecoverySuggestion() {
        let error = MediaControllerError.eventCreationFailed
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion!.contains("重启"))
    }

    @Test("MediaControllerError conforms to LocalizedError")
    func mediaControllerErrorConformsToLocalizedError() {
        let error: MediaControllerError = .permissionDenied
        #expect(error is LocalizedError)
    }

    @Test("MediaControllerError conforms to Sendable")
    func mediaControllerErrorConformsToSendable() {
        // Sendable is a marker protocol, verify the error type is Sendable by checking it satisfies the protocol
        func assertSendable<T: Sendable>(_ value: T) {}
        let error: MediaControllerError = .eventCreationFailed
        assertSendable(error)
    }

    // MARK: - MediaHTTPServerError Tests

    @Test("MediaHTTPServerError startFailed has correct description")
    func mediaHTTPServerErrorStartFailedDescription() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = MediaHTTPServerError.startFailed(underlyingError)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("启动失败"))
    }

    @Test("MediaHTTPServerError invalidPort has correct description")
    func mediaHTTPServerErrorInvalidPortDescription() {
        let error = MediaHTTPServerError.invalidPort
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("端口"))
    }

    @Test("MediaHTTPServerError networkError has correct description")
    func mediaHTTPServerErrorNetworkErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = MediaHTTPServerError.networkError(underlyingError)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("网络错误"))
    }

    @Test("MediaHTTPServerError conforms to LocalizedError")
    func mediaHTTPServerErrorConformsToLocalizedError() {
        let error: MediaHTTPServerError = .invalidPort
        #expect(error is LocalizedError)
    }
}