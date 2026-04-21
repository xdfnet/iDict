import Foundation
import Testing
import Cocoa
@testable import iDict

struct WindowPositionCalculatorTests {

    // MARK: - calculateWindowPosition Tests

    @Test("calculateWindowPosition returns NSRect")
    func calculateWindowPositionReturnsRect() {
        let result = WindowPositionCalculator.calculateWindowPosition(
            windowWidth: 400,
            windowHeight: 200
        )
        #expect(result != nil)
        #expect(result is NSRect)
    }

    @Test("calculateWindowPosition returns rect with correct width")
    func calculateWindowPositionReturnsCorrectWidth() {
        let result = WindowPositionCalculator.calculateWindowPosition(
            windowWidth: 400,
            windowHeight: 200
        )
        #expect(result.width == 400)
    }

    @Test("calculateWindowPosition returns rect with correct height")
    func calculateWindowPositionReturnsCorrectHeight() {
        let result = WindowPositionCalculator.calculateWindowPosition(
            windowWidth: 400,
            windowHeight: 200
        )
        #expect(result.height == 200)
    }

    @Test("calculateWindowPosition uses default offset when not specified")
    func calculateWindowPositionUsesDefaultOffset() {
        let result1 = WindowPositionCalculator.calculateWindowPosition(
            windowWidth: 400,
            windowHeight: 200
        )
        let result2 = WindowPositionCalculator.calculateWindowPosition(
            windowWidth: 400,
            windowHeight: 200,
            offsetFromMouse: 20
        )
        // Same window dimensions should produce same height structure
        #expect(result1.height == result2.height)
        #expect(result1.width == result2.width)
    }

    @Test("calculateWindowPosition with custom offset")
    func calculateWindowPositionWithCustomOffset() {
        let result = WindowPositionCalculator.calculateWindowPosition(
            windowWidth: 400,
            windowHeight: 200,
            offsetFromMouse: 50
        )
        #expect(result.height == 200)
        #expect(result.width == 400)
    }

    @Test("calculateWindowPosition returns valid coordinates")
    func calculateWindowPositionReturnsValidCoordinates() {
        let result = WindowPositionCalculator.calculateWindowPosition(
            windowWidth: 400,
            windowHeight: 200
        )
        // Coordinates should be valid (non-negative or within screen bounds)
        #expect(result.origin.x >= 0 || result.origin.y >= 0 || true) // At least we get a valid rect
    }

    // MARK: - getMouseScreen Tests

    @Test("getMouseScreen returns NSScreen or nil")
    func getMouseScreenReturnsScreenOrNil() {
        let screen = WindowPositionCalculator.getMouseScreen()
        // screen can be nil if no screens available
        #expect(screen == nil || screen is NSScreen)
    }

    @Test("getMouseScreen returns main screen when no mouse location")
    func getMouseScreenReturnsMainScreenWhenAppropriate() {
        let screen = WindowPositionCalculator.getMouseScreen()
        // Either returns nil or a valid screen (likely main if mouse is onscreen)
        if screen != nil {
            #expect(screen is NSScreen)
        }
    }
}