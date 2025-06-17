import Combine
import Foundation
import SwiftUI

public protocol ScreenSleepControlling {
    func disableScreenSleep()
    func enableScreenSleep()
}

/// Контроллер для управления блокировкой экрана устройства
public final class ScreenSleepController: ScreenSleepControlling {

    /// Статический экземпляр для глобального использования
    public static let shared = ScreenSleepController()

    /// Текущее состояние блокировки экрана
    @Published public private(set) var isScreenSleepDisabled: Bool = false

    /// Отслеживает, было ли блокировка отключена программно
    private var wasDisabledProgrammatically: Bool = false

    /// Cancellables для подписок на уведомления
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupAppStateObservation()
    }

    /// Отключает автоматическую блокировку экрана
    /// Используется когда нужно предотвратить засыпание экрана (например, во время голосового чата)
    public func disableScreenSleep() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
            self.isScreenSleepDisabled = true
            self.wasDisabledProgrammatically = true
        }
    }

    /// Включает автоматическую блокировку экрана
    /// Возвращает стандартное поведение системы по блокировке экрана
    public func enableScreenSleep() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
            self.isScreenSleepDisabled = false
            self.wasDisabledProgrammatically = false
        }
    }

    /// Переключает состояние блокировки экрана
    public func toggleScreenSleep() {
        if isScreenSleepDisabled {
            enableScreenSleep()
        } else {
            disableScreenSleep()
        }
    }

    /// Настройка отслеживания состояния приложения
    private func setupAppStateObservation() {
        // Автоматически включаем блокировку экрана при переходе в фоновый режим
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)

        // Восстанавливаем состояние при возвращении в активный режим
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
    }

    private func handleAppDidEnterBackground() {
        // В фоновом режиме всегда включаем блокировку экрана для экономии батареи
        if isScreenSleepDisabled {
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false
                self.isScreenSleepDisabled = false
                // Сохраняем информацию, что блокировка была отключена программно
            }
        }
    }

    private func handleAppDidBecomeActive() {
        // Восстанавливаем состояние только если оно было отключено программно
        if wasDisabledProgrammatically && !isScreenSleepDisabled {
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = true
                self.isScreenSleepDisabled = true
            }
        }
    }
}
