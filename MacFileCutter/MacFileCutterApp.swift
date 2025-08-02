//
//  MacFileCutterApp.swift
//  MacFileCutter
//
//  Created by Digkill on 31.07.2025.
//

import Cocoa
import os.log

class AppDelegate: NSObject, NSApplicationDelegate {
    var cutPaths: [String] = []
    var eventTap: CFMachPort?
    var runLoopSource: CFRunLoopSource?
    private let log = OSLog(subsystem: "com.yourapp.MacFileCutter", category: "debug")

    func applicationDidFinishLaunching(_ notification: Notification) {
        os_log(.info, log: log, "🚀 MacFileCutter launched")
        print("🚀 MacFileCutter launched")

        setupEventTap()
        addStatusBarItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            os_log(.info, log: log, "🛑 EventTap stopped")
            print("🛑 EventTap stopped")
        }
    }

    func setupEventTap() {
        os_log(.info, log: log, "🔍 Attempting to create CGEventTap")
        print("🔍 Attempting to create CGEventTap")
        
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let flags = event.flags
                let keycode = event.getIntegerValueField(.keyboardEventKeycode)
                print("🔑 Keycode: \(keycode), Flags: \(flags.rawValue)")
                let delegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()

                if flags.contains(.maskCommand) {
                    switch keycode {
                    case 7: // Cmd + X
                        delegate.cutPaths = delegate.getSelectedFinderItems()
                        let message = delegate.cutPaths.isEmpty
                            ? "⚠️ No files selected for cutting"
                            : "✂️ Cut: \(delegate.cutPaths.joined(separator: ", "))"
                        os_log(.info, log: delegate.log, "%{public}@", message)
                        print(message)
                    case 9: // Cmd + V
                        if let dest = delegate.getCurrentFinderDirectory(), !delegate.cutPaths.isEmpty {
                            delegate.moveFiles(delegate.cutPaths, to: dest)
                            delegate.cutPaths.removeAll()
                        } else {
                            os_log(.error, log: delegate.log, "⚠️ Failed to determine destination folder or no files cut")
                            print("⚠️ Failed to determine destination folder or no files cut")
                        }
                    default:
                        break
                    }
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            let errorMsg = "❌ Failed to create CGEventTap. Ensure 'Input Monitoring' and 'Accessibility' permissions are granted in System Settings."
            os_log(.error, log: log, "%{public}@", errorMsg)
            print(errorMsg)
            exit(1)
        }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        os_log(.info, log: log, "🎯 EventTap activated")
        print("🎯 EventTap activated")
    }

    func addStatusBarItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "MacFileCutter")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminate), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func terminate() {
        NSApplication.shared.terminate(nil)
    }

    private func getSelectedFinderItems() -> [String] {
        let script = """
        tell application "Finder"
            activate
            set sel to selection
            set paths to {}
            repeat with i in sel
                try
                    set end of paths to POSIX path of (i as alias)
                end try
            end repeat
            return paths
        end tell
        """
        let result = runAppleScript(script)
        os_log(.info, log: log, "📋 Selected in Finder: %{public}@", result.description)
        print("📋 Selected in Finder: \(result)")
        return result
    }

    private func getCurrentFinderDirectory() -> String? {
        let script = """
        tell application "Finder"
            activate
            try
                set thePath to POSIX path of (target of front Finder window as alias)
                return thePath
            on error
                return ""
            end try
        end tell
        """
        let result = runAppleScript(script).first
        os_log(.info, log: log, "📂 Current Finder directory: %{public}@", result ?? "nil")
        print("📂 Current Finder directory: \(result ?? "nil")")
        return result
    }

    private func runAppleScript(_ script: String) -> [String] {
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            let errorMsg = "❌ Failed to create AppleScript"
            os_log(.error, log: log, "%{public}@", errorMsg)
            print(errorMsg)
            return []
        }

        let result = scriptObject.executeAndReturnError(&error)
        if let error = error {
            let errorMsg = "❌ AppleScript error: \(error["NSAppleScriptErrorMessage"] ?? "unknown error"), Code: \(error["NSAppleScriptErrorNumber"] ?? 0)"
            os_log(.error, log: log, "%{public}@", errorMsg)
            print(errorMsg)
            return []
        }

        os_log(.info, log: log, "✅ AppleScript executed successfully")
        print("✅ AppleScript executed successfully")
        if result.descriptorType == typeAEList {
            return (1...result.numberOfItems).compactMap { result.atIndex($0)?.stringValue }
        } else if let value = result.stringValue, !value.isEmpty {
            return [value]
        }
        return []
    }

    private func moveFiles(_ paths: [String], to destination: String) {
        let fm = FileManager.default
        let destURL = URL(fileURLWithPath: destination, isDirectory: true)

        for path in paths {
            let srcURL = URL(fileURLWithPath: path)
            let fileName = srcURL.lastPathComponent
            let dstURL = destURL.appendingPathComponent(fileName)

            guard fm.fileExists(atPath: srcURL.path) else {
                let errorMsg = "❌ File does not exist: \(path)"
                os_log(.error, log: log, "%{public}@", errorMsg)
                print(errorMsg)
                continue
            }

            if fm.fileExists(atPath: dstURL.path) {
                let warningMsg = "⚠️ File already exists: \(fileName). Skipped."
                os_log(.error, log: log, "%{public}@", warningMsg) // Изменено с .warning на .error
                print(warningMsg)
                continue
            }

            do {
                try fm.moveItem(at: srcURL, to: dstURL)
                let successMsg = "✅ Moved: \(fileName) → \(destination)"
                os_log(.info, log: log, "%{public}@", successMsg)
                print(successMsg)
            } catch {
                let errorMsg = "❌ Error moving file: \(error.localizedDescription)"
                os_log(.error, log: log, "%{public}@", errorMsg)
                print(errorMsg)
            }
        }
    }
}
