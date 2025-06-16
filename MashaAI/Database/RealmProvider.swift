import Foundation
import RealmSwift

class RealmProvider {
    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration) {
        self.configuration = configuration
    }

    var realm: Realm {
        do {
            return try Realm(configuration: configuration)
        } catch {
            assertionFailure("Realm initialization failed: \(error)")
            // Fallback to an in-memory Realm to keep the app alive.
            return try! Realm(configuration: .init(inMemoryIdentifier: "fallback"))
        }
    }
}

extension RealmProvider {
    static var main: RealmProvider {
        var configuration = Realm.Configuration.defaultConfiguration
        // TODO: debug only
        configuration.deleteRealmIfMigrationNeeded = true

        return RealmProvider(configuration: configuration)
    }
}
