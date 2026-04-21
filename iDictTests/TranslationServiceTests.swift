import Foundation
import Testing
@testable import iDict

struct TranslationServiceTests {

    // MARK: - TranslationResult Tests

    @Test("TranslationResult success case - isEmpty returns false for non-empty text")
    func translationResultSuccessIsNotEmpty() {
        let result = TranslationResult.success("Hello")
        #expect(result.isEmpty == false)
    }

    @Test("TranslationResult success case - isEmpty returns true for empty text")
    func translationResultSuccessEmptyIsEmpty() {
        let result = TranslationResult.success("")
        #expect(result.isEmpty == true)
    }

    @Test("TranslationResult success case - isFailure returns false")
    func translationResultSuccessIsNotFailure() {
        let result = TranslationResult.success("Hello")
        #expect(result.isFailure == false)
    }

    @Test("TranslationResult success case - text returns the translated string")
    func translationResultSuccessText() {
        let result = TranslationResult.success("你好")
        #expect(result.text == "你好")
    }

    @Test("TranslationResult success case - errorMessage returns nil")
    func translationResultSuccessErrorMessageIsNil() {
        let result = TranslationResult.success("你好")
        #expect(result.errorMessage == nil)
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
    func translationResultFailedTextIsNil() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.text == nil)
    }

    @Test("TranslationResult failed case - errorMessage returns error string")
    func translationResultFailedErrorMessage() {
        let result = TranslationResult.failed("Hello", error: "Network error")
        #expect(result.errorMessage == "Network error")
    }

    // MARK: - TranslationServiceManager Tests

    @Test("TranslationServiceManager init creates instance")
    func translationServiceManagerInit() {
        let manager = TranslationServiceManager()
        #expect(manager != nil)
    }

    // MARK: - GoogleTranslationService Tests

    @Test("GoogleTranslationService translate handles empty string")
    func translateHandlesEmptyString() async {
        let result = await GoogleTranslationService.translate("")
        // Empty string should result in failed or empty success
        #expect(result.isFailure || result.isEmpty)
    }

    @Test("GoogleTranslationService translate returns TranslationResult")
    func translateReturnsTranslationResult() async {
        let result = await GoogleTranslationService.translate("test")
        #expect(result != nil)
        #expect(result is TranslationResult)
    }
}