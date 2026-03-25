import AppKit
import Carbon.HIToolbox

enum PasteHelper {
    static func paste(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let source = CGEventSource(stateID: .hidSystemState)
            guard let keyDown = CGEvent(keyboardEventSource: source,
                                        virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source,
                                      virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
            else { return }

            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
            usleep(50_000)
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
