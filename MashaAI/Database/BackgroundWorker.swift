import Foundation

/// Executes blocks on a background thread with run loop (used by Realm to receive notifications)
class BackgroundWorker: NSObject {
    var thread: Thread!

    override init() {
        super.init()
        start()
    }

    func execute(_ block: @escaping () -> Void) {
        guard thread?.isCancelled == false else {
            assertionFailure("Worker should be started")
            return
        }

        let selector = #selector(runBlock)

        perform(
            selector,
            on: thread,
            with: block,
            waitUntilDone: false,
            modes: [RunLoop.Mode.default.rawValue]
        )
    }

    func start() {
        let threadName = String(describing: self)
            .components(separatedBy: .punctuationCharacters)[1]

        thread = Thread { [weak self] in

            let dummySource = Port()
            RunLoop.current.add(dummySource, forMode: .default)

            while let thread = self?.thread, !thread.isCancelled {
                RunLoop.current.run(mode: .default,
                                    before: .distantFuture)
            }

            dummySource.invalidate()
            Thread.exit()
        }

        thread?.name = "\(threadName)-\(UUID().uuidString)"
        thread?.start()
    }

    @objc
    private func runBlock(_ block: Any?) {
        if let block = block as? (() -> Void) {
            block()
        }
    }

    public func stop() {
        thread?.cancel()
    }
}
