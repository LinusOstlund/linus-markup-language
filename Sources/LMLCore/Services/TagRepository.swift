import Foundation

/// Persists and retrieves the most-recently-used XML action tags.
///
/// The protocol exists so view models can be unit-tested against an
/// in-memory fake instead of touching `UserDefaults.standard`.
public protocol TagRepositoryProtocol: AnyObject {
    func loadRecent() -> [Tag]
    func record(_ tag: Tag)
    func clear()
}

public final class TagRepository: TagRepositoryProtocol {

    private let defaults: UserDefaults
    private let key: String
    private let maxCount: Int

    public init(
        defaults: UserDefaults = .standard,
        key: String = "recentActionTypes",
        maxCount: Int = 10
    ) {
        self.defaults = defaults
        self.key = key
        self.maxCount = maxCount
    }

    public func loadRecent() -> [Tag] {
        (defaults.stringArray(forKey: key) ?? []).map(Tag.init(name:))
    }

    /// Moves `tag` to the front of the list, removing any previous occurrence,
    /// and trims the tail to `maxCount` entries.
    public func record(_ tag: Tag) {
        var tags = loadRecent().map(\.name)
        tags.removeAll { $0 == tag.name }
        tags.insert(tag.name, at: 0)
        if tags.count > maxCount { tags = Array(tags.prefix(maxCount)) }
        defaults.set(tags, forKey: key)
    }

    public func clear() {
        defaults.removeObject(forKey: key)
    }
}
