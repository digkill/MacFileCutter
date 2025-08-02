# ✂️ FileCutter — macOS File Cut & Paste Utility

**FileCutter** is a lightweight macOS background utility that enables true **Cut (`Cmd + X`) and Paste (`Cmd + V`)** functionality for files and folders in Finder — just like on Windows and Linux.
No more dragging files or copying without removing them — FileCutter gives you a real file-cutting workflow.

---

## 🚀 Features
- **Cut files/folders with `Cmd + X`**
- **Paste files/folders with `Cmd + V`** into the current Finder directory
- Works **globally** in Finder using low-level keyboard hooks (`CGEventTap`)
- Runs in the background with a **menu bar icon**
- Fully **sandbox-free** for proper file operations
- Auto-start support via **LaunchAgent**

---

## 📦 Installation
1. **Download** the latest `.dmg` from the Releases page *(coming soon)*.
2. Drag **`MacFileCutter.app`** to your **Applications** folder.
3. Add the app to **System Settings → Security & Privacy → Accessibility** so it can intercept global hotkeys.
4. (Optional) Enable autostart:
   ```bash
   cp ~/Applications/MacFileCutter.app/Contents/Resources/org.mediarise.filecutter.plist ~/Library/LaunchAgents/
   launchctl load ~/Library/LaunchAgents/org.mediarise.filecutter.plist
   ```

---

## 🛠 Usage
1. **Select** files or folders in Finder.
2. Press `Cmd + X` — the selection is now marked for cutting.
3. Navigate to the destination folder.
4. Press `Cmd + V` — the files will be moved to the new location.

---

## ⚙️ Technical Details
- **Language:** Swift
- **Frameworks:** Cocoa, CoreGraphics
- **Key Components:**
  - `CGEventTap` for global hotkey interception
  - `NSAppleScript` for interacting with Finder
  - `FileManager` for safe file moves
  - Menu bar interface with `NSStatusBarItem`
- **macOS Support:** macOS 12+ (tested on Sonoma)

---

## 🔐 Permissions
For FileCutter to work, you **must** grant Accessibility permissions:
- Open **System Settings → Security & Privacy → Accessibility**
- Add **`MacFileCutter.app`**
- Enable it

---

## 🖼 Status Bar Icon
- ✂️ — Running in background
- Click it for menu options (Quit, About, etc.)

---

## 📜 License
MIT License — you are free to use, modify, and distribute this software.
