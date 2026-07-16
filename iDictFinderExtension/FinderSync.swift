//
//  FinderSync.swift
//  iDictFinderExtension
//  右键 → Terminal
//

import Cocoa
import FinderSync
import Carbon

class FinderSync: FIFinderSync {

    override init() {
        super.init()
        let sync = FIFinderSyncController.default()
        if let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: [.skipHiddenVolumes]
        ) {
            sync.directoryURLs = Set(volumes)
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil, queue: .main
        ) { note in
            if let url = note.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                sync.directoryURLs.insert(url)
            }
        }
    }

    override var toolbarItemName: String { "Terminal" }
    override var toolbarItemToolTip: String { "在 Finder 目录打开终端" }
    override var toolbarItemImage: NSImage {
        .init(systemSymbolName: "terminal.fill", accessibilityDescription: nil) ?? .init()
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        let item = NSMenuItem(
            title: "Terminal",
            action: #selector(openTerminal),
            keyEquivalent: ""
        )
        if #available(macOS 11.0, *) {
            item.image = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: nil)
        }
        menu.addItem(item)
        return menu
    }

    @objc func openTerminal() {
        guard let url = targetURL() else { return }
        let path = url.path

        guard let dir = try? FileManager.default.url(
            for: .applicationScriptsDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ) else { return }

        let scriptURL = dir.appendingPathComponent("terminal.scpt")
        guard FileManager.default.fileExists(atPath: scriptURL.path),
              let task = try? NSUserAppleScriptTask(url: scriptURL) else { return }

        // 按 OpenInTerminal 的方式传递参数
        let argList = NSAppleEventDescriptor.list()
        argList.insert(NSAppleEventDescriptor(string: path), at: 1)

        let params = NSAppleEventDescriptor.list()
        params.insert(argList, at: 1)

        let event = NSAppleEventDescriptor(
            eventClass: AEEventClass(kASAppleScriptSuite),
            eventID: AEEventID(kASSubroutineEvent),
            targetDescriptor: nil,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        event.setDescriptor(
            NSAppleEventDescriptor(string: "openTerminal"),
            forKeyword: AEKeyword(keyASSubroutineName)
        )
        event.setDescriptor(params, forKeyword: AEKeyword(keyDirectObject))

        task.execute(withAppleEvent: event) { _, _ in }
    }

    private func targetURL() -> URL? {
        if let items = FIFinderSyncController.default().selectedItemURLs(), !items.isEmpty {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: items[0].path, isDirectory: &isDir) {
                return isDir.boolValue ? items[0] : items[0].deletingLastPathComponent()
            }
        }
        return FIFinderSyncController.default().targetedURL()
    }
}
