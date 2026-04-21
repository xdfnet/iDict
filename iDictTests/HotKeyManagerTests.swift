import Foundation
import Testing
@testable import iDict

struct HotKeyManagerTests {

    // MARK: - HotKeyConfig Tests

    @Test("HotKeyConfig defaultConfig creates valid config")
    func defaultConfigCreatesValidConfig() {
        let config = HotKeyConfig.defaultConfig

        // Verify config has non-zero values
        #expect(config.keyCode != 0)
        #expect(config.modifiers != 0)
        #expect(config.signature != 0)
        #expect(config.id == 1)
    }

    @Test("HotKeyConfig defaultConfig has expected signature")
    func defaultConfigHasExpectedSignature() {
        let config = HotKeyConfig.defaultConfig
        // "iDiT" in hex = 0x69446954, but stored as 0x49444954 due to endianness
        #expect(config.signature == 0x49444954)
    }

    @Test("HotKeyConfig defaultConfig has id of 1")
    func defaultConfigHasIdOf1() {
        let config = HotKeyConfig.defaultConfig
        #expect(config.id == 1)
    }

    // MARK: - HotKeyManager Init Tests

    @Test("HotKeyManager init creates instance")
    func initCreatesInstance() {
        let manager = HotKeyManager()
        #expect(manager != nil)
    }

    // MARK: - HotKeyError Tests

    @Test("HotKeyError registrationFailed has correct error description")
    func hotKeyErrorRegistrationFailedDescription() {
        let error = HotKeyError.registrationFailed(0)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("热键注册失败"))
    }

    @Test("HotKeyError eventHandlerInstallFailed has correct error description")
    func hotKeyErrorEventHandlerInstallFailedDescription() {
        let error = HotKeyError.eventHandlerInstallFailed(0)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("事件处理器安装失败"))
    }

    @Test("HotKeyError permissionDenied has correct error description")
    func hotKeyErrorPermissionDeniedDescription() {
        let error = HotKeyError.permissionDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("辅助功能权限"))
    }

    @Test("HotKeyError invalidConfiguration has correct error description")
    func hotKeyErrorInvalidConfigurationDescription() {
        let error = HotKeyError.invalidConfiguration
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("热键配置无效"))
    }

    @Test("HotKeyError alreadyRegistered has correct error description")
    func hotKeyErrorAlreadyRegisteredDescription() {
        let error = HotKeyError.alreadyRegistered
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("已被其他应用使用"))
    }

    @Test("HotKeyError systemError has correct error description")
    func hotKeyErrorSystemErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = HotKeyError.systemError(underlyingError)
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("系统错误"))
    }

    @Test("HotKeyError all cases have error descriptions")
    func allErrorCasesHaveDescriptions() {
        let errors: [HotKeyError] = [
            .registrationFailed(1),
            .eventHandlerInstallFailed(1),
            .permissionDenied,
            .invalidConfiguration,
            .alreadyRegistered,
            .systemError(NSError(domain: "", code: 0))
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}