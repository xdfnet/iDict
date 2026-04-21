import Foundation
import Testing
import AppKit
@testable import iDict

struct ClipboardManagerTests {

    // MARK: - ClipboardManager Init Tests

    @Test("ClipboardManager init creates instance")
    func initCreatesInstance() {
        let manager = ClipboardManager()
        #expect(manager != nil)
    }

    // MARK: - cleanClipboardText Tests

    @Test("cleanClipboardText removes pipe character")
    func cleanTextRemovesPipe() {
        let manager = ClipboardManager()
        let text = "Hello │ World"
        let cleaned = manager.cleanClipboardText(text)
        #expect(!cleaned.contains("│"))
        #expect(cleaned == "Hello World")
    }

    @Test("cleanClipboardText trims whitespace")
    func cleanTextTrimsWhitespace() {
        let manager = ClipboardManager()
        let text = "   Hello World   "
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "Hello World")
    }

    @Test("cleanClipboardText collapses multiple spaces")
    func cleanTextCollapsesSpaces() {
        let manager = ClipboardManager()
        let text = "Hello    World"
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "Hello World")
    }

    @Test("cleanClipboardText handles empty string")
    func cleanTextHandlesEmptyString() {
        let manager = ClipboardManager()
        let text = ""
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "")
    }

    @Test("cleanClipboardText handles only whitespace and pipes")
    func cleanTextHandlesOnlyWhitespaceAndPipes() {
        let manager = ClipboardManager()
        let text = "   │   │   "
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "")
    }

    @Test("cleanClipboardText preserves unicode")
    func cleanTextPreservesUnicode() {
        let manager = ClipboardManager()
        let text = "你好 │ 世界"
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "你好 世界")
    }

    @Test("cleanClipboardText multiple pipe characters")
    func cleanTextMultiplePipes() {
        let manager = ClipboardManager()
        let text = "│││text│││"
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "text")
    }

    @Test("cleanClipboardText handles tabs")
    func cleanTextHandlesTabs() {
        let manager = ClipboardManager()
        let text = "Hello\tWorld"
        let cleaned = manager.cleanClipboardText(text)
        #expect(cleaned == "Hello World")
    }

    // MARK: - ClipboardError Tests

    @Test("ClipboardError emptyOrNonText has correct description")
    func clipboardErrorEmptyOrNonTextDescription() {
        let error = ClipboardError.emptyOrNonText
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("剪贴板"))
        #expect(error.errorDescription!.contains("文本"))
    }

    @Test("ClipboardError textTooLong has correct description")
    func clipboardErrorTextTooLongDescription() {
        let error = ClipboardError.textTooLong
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("过长"))
    }

    @Test("ClipboardError conforms to LocalizedError")
    func clipboardErrorConformsToLocalizedError() {
        let error: ClipboardError = .emptyOrNonText
        #expect(error is LocalizedError)
    }
}