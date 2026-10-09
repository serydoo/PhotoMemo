import Foundation

/// Presentation authority is separate from execution ownership. This bounded
/// heartbeat only suppresses duplicate UI; the file lock owns execution.
nonisolated enum ProcessingPresentationAuthority: Equatable {
    case systemContinuedProcessing
    case activityKit

    private struct Heartbeat: Codable {
        let leaseID: UUID
        let expiresAt: Date
    }
    private static let key = "memomark.processing.systemPresentationHeartbeat"

    static func current(defaults: UserDefaults, now: Date = Date()) -> Self {
        defaults.synchronize()
        guard let heartbeat = read(defaults), heartbeat.expiresAt > now else { return .activityKit }
        return .systemContinuedProcessing
    }

    static func renew(leaseID: UUID, defaults: UserDefaults, now: Date = Date()) {
        let heartbeat = Heartbeat(leaseID: leaseID, expiresAt: now.addingTimeInterval(60))
        guard let data = try? JSONEncoder().encode(heartbeat) else { return }
        defaults.set(data, forKey: key)
        defaults.synchronize()
    }

    static func release(leaseID: UUID, defaults: UserDefaults) {
        defaults.synchronize()
        guard read(defaults)?.leaseID == leaseID else { return }
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }

    private static func read(_ defaults: UserDefaults) -> Heartbeat? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Heartbeat.self, from: data)
    }
}
