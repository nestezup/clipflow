import Carbon.HIToolbox
import AppKit

final class HotkeyManager {
    private var eventHandler: EventHandlerRef?
    private let onTogglePanel: () -> Void
    private let onItemSelect: (Int) -> Void
    private let onDismiss: () -> Void

    private var itemHotKeyRefs: [EventHotKeyRef?] = []
    private var escHotKeyRef: EventHotKeyRef?

    init(onTogglePanel: @escaping () -> Void,
         onItemSelect: @escaping (Int) -> Void,
         onDismiss: @escaping () -> Void) {
        self.onTogglePanel = onTogglePanel
        self.onItemSelect = onItemSelect
        self.onDismiss = onDismiss
    }

    /// ⌥V 글로벌 핫키 등록
    func registerToggle() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x434C_4950) // "CLIP"
        hotKeyID.id = 100

        var hotKeyRef: EventHotKeyRef?
        RegisterEventHotKey(UInt32(kVK_ANSI_V), UInt32(optionKey), hotKeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData, let event else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            DispatchQueue.main.async {
                switch hotKeyID.id {
                case 100:
                    manager.onTogglePanel()
                case 200:
                    manager.onDismiss()
                case 1...9:
                    manager.onItemSelect(Int(hotKeyID.id) - 1)
                default:
                    break
                }
            }
            return noErr
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType,
                            selfPointer, &eventHandler)
    }

    /// 패널 열릴 때: 1~9 + ESC 핫키 등록
    func registerItemKeys() {
        guard itemHotKeyRefs.isEmpty else { return }

        let keyCodes: [UInt32] = [
            UInt32(kVK_ANSI_1), UInt32(kVK_ANSI_2), UInt32(kVK_ANSI_3),
            UInt32(kVK_ANSI_4), UInt32(kVK_ANSI_5), UInt32(kVK_ANSI_6),
            UInt32(kVK_ANSI_7), UInt32(kVK_ANSI_8), UInt32(kVK_ANSI_9),
        ]

        for (i, keyCode) in keyCodes.enumerated() {
            var hotKeyID = EventHotKeyID()
            hotKeyID.signature = OSType(0x434C_4950)
            hotKeyID.id = UInt32(i + 1)

            var ref: EventHotKeyRef?
            RegisterEventHotKey(keyCode, 0, hotKeyID, GetApplicationEventTarget(), 0, &ref)
            itemHotKeyRefs.append(ref)
        }

        // ESC
        var escID = EventHotKeyID()
        escID.signature = OSType(0x434C_4950)
        escID.id = 200
        RegisterEventHotKey(UInt32(kVK_Escape), 0, escID, GetApplicationEventTarget(), 0, &escHotKeyRef)
    }

    /// 패널 닫힐 때: 1~9 + ESC 핫키 해제
    func unregisterItemKeys() {
        for ref in itemHotKeyRefs {
            if let ref { UnregisterEventHotKey(ref) }
        }
        itemHotKeyRefs.removeAll()

        if let ref = escHotKeyRef {
            UnregisterEventHotKey(ref)
            escHotKeyRef = nil
        }
    }
}
