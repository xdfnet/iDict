import Foundation
import Testing
@testable import iDict

struct iDictTests {

    // MARK: - TranslationResult Tests

    @Test("TranslationResult success case - isEmpty returns false")
    func translationResultSuccessIsEmpty() {
        let result = TranslationResult.success("Hello")
        #expect(result.isEmpty == false)
    }

    @Test("TranslationResult success case - isFailure returns false")
    func translationResultSuccessIsFailure() {
        let result = TranslationResult.success("Hello")
        #expect(result.isFailure == false)
    }

    @Test("TranslationResult success case - text returns translated string")
    func translationResultSuccessText() {
        let result = TranslationResult.success("你好")
        #expect(result.text == "你好")
    }

    @Test("TranslationResult success case - errorMessage returns nil")
    func translationResultSuccessErrorMessage() {
        let result = TranslationResult.success("你好")
        #expect(result.errorMessage == nil)
    }

    @Test("TranslationResult success case with empty string - isEmpty returns true")
    func translationResultSuccessEmptyIsEmpty() {
        let result = TranslationResult.success("")
        #expect(result.isEmpty == true)
    }

    @Test("TranslationResult failed case - isEmpty returns true")
    func translationResultFailedIsEmpty() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.isEmpty == true)
    }

    @Test("TranslationResult failed case - isFailure returns true")
    func translationResultFailedIsFailure() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.isFailure == true)
    }

    @Test("TranslationResult failed case - text returns nil")
    func translationResultFailedText() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.text == nil)
    }

    @Test("TranslationResult failed case - errorMessage returns error string")
    func translationResultFailedErrorMessage() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.errorMessage == "Network error")
    }

    // MARK: - AppConfig Tests

    @Test("AppConfig getAppConfig - returns App for valid system name 'douyin'")
    func appConfigGetAppConfigBySystemName() {
        let app = AppConfig.getAppConfig(for: "douyin")
        #expect(app != nil)
        #expect(app?.displayName == "抖音")
        #expect(app?.bundleId == "com.bytedance.douyin.desktop")
    }

    @Test("AppConfig getAppConfig - returns App for valid Chinese name '抖音'")
    func appConfigGetAppConfigByChineseName() {
        let app = AppConfig.getAppConfig(for: "抖音")
        #expect(app != nil)
        #expect(app?.systemName == "douyin")
        #expect(app?.bundleId == "com.bytedance.douyin.desktop")
    }

    @Test("AppConfig getAppConfig - returns App for valid system name 'qishui'")
    func appConfigGetAppConfigByQishuiSystemName() {
        let app = AppConfig.getAppConfig(for: "qishui")
        #expect(app != nil)
        #expect(app?.displayName == "汽水音乐")
        #expect(app?.bundleId == "com.soda.music")
    }

    @Test("AppConfig getAppConfig - returns App for valid Chinese name '汽水音乐'")
    func appConfigGetAppConfigByQishuiChineseName() {
        let app = AppConfig.getAppConfig(for: "汽水音乐")
        #expect(app != nil)
        #expect(app?.systemName == "qishui")
        #expect(app?.bundleId == "com.soda.music")
    }

    @Test("AppConfig getAppConfig - returns nil for invalid name")
    func appConfigGetAppConfigInvalidName() {
        let app = AppConfig.getAppConfig(for: "invalid_app_name_12345")
        #expect(app == nil)
    }

    @Test("AppConfig getBundleId - returns correct bundle ID for valid name")
    func appConfigGetBundleIdValidName() {
        let bundleId = AppConfig.getBundleId(for: "douyin")
        #expect(bundleId == "com.bytedance.douyin.desktop")
    }

    @Test("AppConfig getBundleId - returns correct bundle ID for Chinese name")
    func appConfigGetBundleIdChineseName() {
        let bundleId = AppConfig.getBundleId(for: "抖音")
        #expect(bundleId == "com.bytedance.douyin.desktop")
    }

    @Test("AppConfig getBundleId - returns fallback bundle ID for unknown app")
    func appConfigGetBundleIdUnknownApp() {
        let bundleId = AppConfig.getBundleId(for: "unknown_app")
        #expect(bundleId == "com.unknown.unknown_app")
    }

    // MARK: - HTTPResponseHandler Tests

    @Test("HTTPResponseHandler buildJSONResponse - only status")
    func buildJSONResponseOnlyStatus() {
        let json = HTTPResponseHandler.buildJSONResponse(status: "ok")
        #expect(json.contains("\"status\":\"ok\""))
        #expect(!json.contains("\"error\""))
    }

    @Test("HTTPResponseHandler buildJSONResponse - status with error")
    func buildJSONResponseWithError() {
        let json = HTTPResponseHandler.buildJSONResponse(status: "error", error: "Something went wrong")
        #expect(json.contains("\"status\":\"error\""))
        #expect(json.contains("\"error\":\"Something went wrong\""))
    }

    @Test("HTTPResponseHandler buildJSONResponse - status with error and additionalData")
    func buildJSONResponseWithErrorAndAdditionalData() {
        let additionalData: [String: Any] = ["count": 42, "name": "test"]
        let json = HTTPResponseHandler.buildJSONResponse(
            status: "ok",
            error: nil,
            additionalData: additionalData
        )
        #expect(json.contains("\"status\":\"ok\""))
        #expect(json.contains("\"count\":42"))
        #expect(json.contains("\"name\":\"test\""))
    }

    @Test("HTTPResponseHandler buildJSONResponse - additionalData overwrites existing keys")
    func buildJSONResponseAdditionalDataOverwrites() {
        let additionalData: [String: Any] = ["status": "overridden"]
        let json = HTTPResponseHandler.buildJSONResponse(
            status: "original",
            additionalData: additionalData
        )
        #expect(json.contains("\"status\":\"overridden\""))
    }

    @Test("HTTPResponseHandler buildJSONResponse - valid JSON format")
    func buildJSONResponseValidJSONFormat() {
        let json = HTTPResponseHandler.buildJSONResponse(status: "success", error: "no error")
        let data = json.data(using: .utf8)
        #expect(data != nil)
        let parsed = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
        #expect(parsed != nil)
        #expect((parsed?["status"] as? String) == "success")
        #expect((parsed?["error"] as? String) == "no error")
    }

    // MARK: - ClipboardManager Tests

    @Test("ClipboardManager - cleanClipboardText removes pipe character")
    func clipboardCleanTextRemovesPipe() {
        let manager = ClipboardManager()
        let text = "Hello │ World"
        let cleaned = manager.cleanClipboardText(text)
        #expect(!cleaned.contains("│"))
        #expect(cleaned == "Hello World")
    }

    @Test("ClipboardManager - cleanClipboardText trims whitespace")
    func clipboardCleanTextTrimsWhitespace() {
        let manager = ClipboardManager()
        let text = "   Hello World   "
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "Hello World")
    }

    @Test("ClipboardManager - cleanClipboardText collapses multiple spaces")
    func clipboardCleanTextCollapsesSpaces() {
        let manager = ClipboardManager()
        let text = "Hello    World"
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "Hello World")
    }

    @Test("ClipboardManager - cleanClipboardText handles newlines as single component")
    func clipboardCleanTextHandlesNewlines() {
        let manager = ClipboardManager()
        let text = "Hello\nWorld"
        let cleaned = manager.cleanClipboardText(text)
        // .whitespaces does not include newline, so it stays as "Hello\nWorld"
        #expect(cleaned == "Hello\nWorld")
    }

    @Test("ClipboardManager - cleanClipboardText handles tabs")
    func clipboardCleanTextHandlesTabs() {
        let manager = ClipboardManager()
        let text = "Hello\tWorld"
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "Hello World")
    }

    @Test("ClipboardManager - cleanClipboardText multiple pipe characters")
    func clipboardCleanTextMultiplePipes() {
        let manager = ClipboardManager()
        let text = "│││text│││"
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "text")
    }

    @Test("ClipboardManager - cleanClipboardText empty string")
    func clipboardCleanTextEmptyString() {
        let manager = ClipboardManager()
        let text = ""
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "")
    }

    @Test("ClipboardManager - cleanClipboardText only whitespace and pipes")
    func clipboardCleanTextOnlyWhitespaceAndPipes() {
        let manager = ClipboardManager()
        let text = "   │   │   "
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "")
    }

    @Test("ClipboardManager - cleanClipboardText preserves unicode")
    func clipboardCleanTextPreservesUnicode() {
        let manager = ClipboardManager()
        let text = "你好 │ 世界"
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "你好 世界")
    }

    @Test("ClipboardManager - cleanClipboardText complex cleaning")
    func clipboardCleanTextComplexCleaning() {
        let manager = ClipboardManager()
        let text = "  Hello│││World  \n\n\t"
        let cleaned = manager.cleanClipboardText(text)
        // .whitespacesAndNewlines trims trailing \n\n\t, leaving just "HelloWorld"
        #expect(cleaned == "HelloWorld")
    }
}
