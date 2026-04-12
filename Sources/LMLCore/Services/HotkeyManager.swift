import Carbon.HIToolbox

/// Wraps the Carbon Event Manager API for registering a single global hotkey.
///
/// Carbon is deprecated-but-stable — it's the only public API Apple provides
/// for app-wide keyboard shortcuts that work even when the app is not focused.
/// All unsafe `Unmanaged` pointer gymnastics stay hidden inside this class.
public final class HotkeyManager {

    /// Called on the main queue when the registered hotkey fires.
    public var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    /// The currently-registered binding, or `nil` if nothing is registered.
    public private(set) var currentBinding: HotkeyBinding?

    public init() {}

    deinit {
        unregister()
    }

    /// Registers (or re-registers) the global hotkey. Any previously registered
    /// binding is unregistered first.
    public func register(_ binding: HotkeyBinding) {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            carbonCallback,
            1,
            &eventType,
            selfPtr,
            &handlerRef
        )

        let hotkeyID = EventHotKeyID(signature: 0x4C4D4C21, id: 1)  // 'LML!'
        RegisterEventHotKey(
            binding.keyCode,
            binding.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        currentBinding = binding
    }

    public func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
        currentBinding = nil
    }
}

/// Free C-callable function that Carbon requires as the event callback.
/// Recovers `self` from the opaque user-data pointer and dispatches back
/// onto the main queue.
private func carbonCallback(
    _: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

    var hotkeyID = EventHotKeyID()
    GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )

    if hotkeyID.id == 1 {
        DispatchQueue.main.async { manager.onTrigger?() }
    }
    return noErr
}
