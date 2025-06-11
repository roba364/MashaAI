import Foundation
import RealmSwift

class RealmProvider {
    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration) {
        self.configuration = configuration
    }

    var realm: Realm {
        try! Realm(configuration: configuration)
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
