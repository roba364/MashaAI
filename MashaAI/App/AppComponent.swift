import Foundation
import Swinject

@MainActor
class AppComponent: BootstrapDIComponent {
    static let shared = AppComponent()

    private override init() {
        super.init()
    }

    func appCoordinator() -> AppCoordinator {
        AppCoordinator(elementsFactory: self)
    }

    override func setup(with container: Container) {
        container.register(MemoryControlling.self) { r in
            MemoryController(repository: r.resolve())
        }

        container.register(MemoryRepositoring.self) { r in
            MemoryRepository(
                databaseStorage: r.resolve()
            )
        }

        container.register(DatabaseStorage.self) { _ in
            RealmStorage(
                realmProvider: .main
            )
        }
    }
}

extension AppComponent: AppCoordinatorElementsFactory {
    func sessionCoordinator() -> SessionCoordinator {
        SessionComponent(parent: self)
            .sessionCoordinator()
    }

    func onboardingCoordinator() -> OnboardingCoordinator {
        OnboardingComponent(parent: self)
            .onboardingCoordinator()
    }
}

@MainActor
protocol DIComponentProtocol: AnyObject {
    var container: Container { get }
}

class DIComponent: DIComponentProtocol {
    var container: Container
    let parent: DIComponentProtocol

    init(parent: DIComponentProtocol) {
        self.container = Container(parent: parent.container)
        self.parent = parent

        setup(with: container)
    }
}

class BootstrapDIComponent: DIComponentProtocol {
    let container: Container = Container()

    init() {
        setup(with: container)
    }

    func setup(with container: Container) {

    }

}

extension Resolver {
    func resolve<Service>() -> Service {
        guard let service = resolve(Service.self) else {
            fatalError("Failed to resolve: \(Service.self)")
        }
        return service
    }
}

extension DIComponentProtocol {
    func resolve<Service>(_ type: Service.Type = Service.self) -> Service {
        guard let service = container.resolve(Service.self) else {
            fatalError("Failed to resolve: \(Service.self)")
        }
        return service
    }
}
