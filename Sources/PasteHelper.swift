import AppKit
import Carbon.HIToolbox
import os.log

private let logger = Logger(subsystem: "com.clipflow", category: "PasteHelper")

enum PasteHelper {
    static func paste(_ content: ClipContent) {
        let pasteboard = NSPasteboard.general

        switch content {
        case .text(let text):
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)

        case .image(let pngData, _, _):
            guard let image = NSImage(data: pngData),
                  let tiffData = image.tiffRepresentation else {
                logger.error("Failed to convert PNG to TIFF for paste")
                NSSound.beep()
                return
            }
            pasteboard.clearContents()
            pasteboard.setData(tiffData, forType: .tiff)

        case .richText:
            logger.info("richText paste not implemented")
            return

        case .file:
            logger.info("file paste not implemented")
            return
        }

        simulatePaste()
    }

    private static func simulatePaste() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let source = CGEventSource(stateID: .hidSystemState)
            guard let keyDown = CGEvent(keyboardEventSource: source,
                                        virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source,
                                      virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
            else {
                logger.error("Failed to create CGEvent for paste simulation")
                return
            }

            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
            usleep(50_000)
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
