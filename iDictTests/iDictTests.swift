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
