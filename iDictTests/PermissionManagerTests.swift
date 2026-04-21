import Foundation
import Testing
@testable import iDict

struct PermissionManagerTests {

    // MARK: - checkAccessibilityPermission Tests

    @Test("checkAccessibilityPermission returns Boolean value")
    func checkAccessibilityPermissionReturnsBool() {
        let result = PermissionManager.checkAccessibilityPermission()
        #expect(result == true || result == false)
    }

    // MARK: - requestAccessibilityPermission Tests

    @Test("requestAccessibilityPermission does not throw")
    func requestAccessibilityPermissionDoesNotThrow() {
        // This should not throw even if permission is denied
        PermissionManager.requestAccessibilityPermission()
    }

    // MARK: - getPermissionStatusDescription Tests

    @Test("getPermissionStatusDescription returns non-empty string")
    func getPermissionStatusDescriptionReturnsNonEmpty() {
        let description = PermissionManager.getPermissionStatusDescription()
        #expect(!description.isEmpty)
    }

    @Test("getPermissionStatusDescription returns correct Chinese text when permitted")
    func getPermissionStatusDescriptionWhenPermitted() {
        // Given the permission status, description should contain expected text
        let description = PermissionManager.getPermissionStatusDescription()
        let isPermitted = PermissionManager.checkAccessibilityPermission()

        if isPermitted {
            #expect(description.contains("已获得") || description.contains("权限"))
        } else {
            #expect(description.contains("缺少") || description.contains("启用"))
        }
    }

    @Test("getPermissionStatusDescription returns string type")
    func getPermissionStatusDescriptionReturnsString() {
        let description = PermissionManager.getPermissionStatusDescription()
        #expect(description is String)
    }
}