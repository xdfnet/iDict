import Foundation
import Testing
@testable import iDict

struct MenuBarControllerTests {

    // MARK: - MenuBarController Init Tests

    @Test("MenuBarController init creates instance")
    func initCreatesInstance() {
        let controller = MenuBarController()
        #expect(controller != nil)
    }

    // MARK: - cleanup Tests

    @Test("cleanup does not throw")
    func cleanupDoesNotThrow() {
        let controller = MenuBarController()
        controller.cleanup()
        // cleanup should not throw
    }

    // MARK: - performQuickTranslation Tests

    @Test("performQuickTranslation does not throw")
    func performQuickTranslationDoesNotThrow() {
        let controller = MenuBarController()
        controller.performQuickTranslation(text: "test")
        // Should not throw even with empty or short text
    }

    // MARK: - Callback Property Tests

    @Test("showTranslationWindow callback can be set")
    func showTranslationWindowCallbackCanBeSet() {
        let controller = MenuBarController()
        controller.showTranslationWindow = { text in
            // Just set the callback
        }
        // Should not throw
    }

    @Test("showMessage callback can be set")
    func showMessageCallbackCanBeSet() {
        let controller = MenuBarController()
        controller.showMessage = { message in
            // Just set the callback
        }
        // Should not throw
    }
}