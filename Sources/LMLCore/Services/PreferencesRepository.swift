import Foundation

/// Persists user preferences that aren't recent tags — currently just the
/// hotkey binding. Kept separate from `TagRepository` so each has a single
/// responsibility and can be faked independently in tests.
public protocol PreferencesRepositoryProtocol: AnyObject {
    func loadHotkey() -> HotkeyBinding
    func saveHotkey(_ binding: HotkeyBinding)
}

public final class PreferencesRepository: PreferencesRepositoryProtocol {

    private let defaults: UserDefaults
    private let hotkeyKey: String

    public init(defaults: UserDefaults = .standard, hotkeyKey: String = "hotkeyBinding") {
        self.defaults = defaults
        self.hotkeyKey = hotkeyKey
    }

    public func loadHotkey() -> HotkeyBinding {
        guard
            let data = defaults.data(forKey: hotkeyKey),
            let binding = try? JSONDecoder().decode(HotkeyBinding.self, from: data)
        else {
            return .default
        }
        return binding
    }

    public func saveHotkey(_ binding: HotkeyBinding) {
        guard let data = try? JSONEncoder().encode(binding) else { return }
        defaults.set(data, forKey: hotkeyKey)
    }
}
