import Combine
import ElevenLabsSDK
import Foundation

// MARK: - VoiceChatStore
/// Центральный Store для управления состоянием VoiceChat модуля
/// Реализует UDF (Unidirectional Data Flow) архитектуру
///
/// **Принципы работы:**
/// 1. Все изменения состояния происходят только через dispatch actions
/// 2. State является единственным источником истины
/// 3. View подписывается на изменения state через Combine
/// 4. Side effects обрабатываются в Interactor
@MainActor
final class VoiceChatStore: ObservableObject {

  // MARK: - Published State
  /// Текущее состояние VoiceChat модуля
  /// Это единственный источник истины для всех UI компонентов
  @Published private(set) var state = VoiceChatState()

  // MARK: - Private Properties
  private let reducer: (VoiceChatState, VoiceChatAction) -> VoiceChatState
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  /// Инициализирует Store с заданным редюсером
  /// - Parameter reducer: Функция для обработки actions и обновления state
  init(
    reducer: @escaping (VoiceChatState, VoiceChatAction) -> VoiceChatState = VoiceChatReducer.reduce
  ) {
    self.reducer = reducer

    setupLogging()
  }

  // MARK: - Public Methods

  /// Отправляет действие в Store для обработки
  /// Это единственный способ изменить состояние в UDF архитектуре
  /// - Parameter action: Действие для обработки
  func dispatch(_ action: VoiceChatAction) {
    let previousState = state
    let newState = reducer(state, action)

    // Обновляем состояние только если оно действительно изменилось
    if newState != previousState {
      state = newState
      logStateChange(from: previousState, to: newState, action: action)
    }
  }

  /// Асинхронная версия dispatch для вызова из async контекста
  /// - Parameter action: Действие для обработки
  func dispatch(_ action: VoiceChatAction) async {
    await MainActor.run {
      dispatch(action)
    }
  }
}

// MARK: - Convenience Accessors
extension VoiceChatStore {

  /// Удобный доступ к отдельным частям состояния для View
  var viewState: VoiceChatState.ViewState {
    state.viewState
  }

  var isConnected: Bool {
    state.isConnected
  }

  var isConnecting: Bool {
    state.isConnecting
  }

  var isAISpeaking: Bool {
    state.isAISpeaking
  }

  var audioLevel: Float {
    state.audioLevel
  }

  var lastError: String? {
    state.lastError
  }

  var mode: ElevenLabsSDK.Mode {
    state.mode
  }

  var status: ElevenLabsSDK.Status {
    state.status
  }
}

// MARK: - Publisher Extensions
extension VoiceChatStore {

  /// Publisher для отслеживания изменений viewState
  var viewStatePublisher: AnyPublisher<VoiceChatState.ViewState, Never> {
    $state
      .map(\.viewState)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  /// Publisher для отслеживания ошибок
  var errorPublisher: AnyPublisher<String?, Never> {
    $state
      .map(\.lastError)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  /// Publisher для отслеживания состояния речи AI
  var isAISpeakingPublisher: AnyPublisher<Bool, Never> {
    $state
      .map(\.isAISpeaking)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
}

// MARK: - Debug & Logging
extension VoiceChatStore {

  /// Настраивает логирование изменений состояния
  fileprivate func setupLogging() {
    #if DEBUG
      $state
        .removeDuplicates()
        .sink { state in
          print("🏪 Store State Updated: \(state)")
        }
        .store(in: &cancellables)
    #endif
  }

  /// Логирует изменения состояния с подробностями
  fileprivate func logStateChange(
    from previousState: VoiceChatState,
    to newState: VoiceChatState,
    action: VoiceChatAction
  ) {
    #if DEBUG
      print("🔄 Action: \(action)")

      // Логируем только изменившиеся поля
      if previousState.viewState != newState.viewState {
        print("   viewState: \(previousState.viewState) → \(newState.viewState)")
      }

      if previousState.status != newState.status {
        print("   status: \(previousState.status) → \(newState.status)")
      }

      if previousState.isConnecting != newState.isConnecting {
        print("   isConnecting: \(previousState.isConnecting) → \(newState.isConnecting)")
      }

      if previousState.isAISpeaking != newState.isAISpeaking {
        print("   isAISpeaking: \(previousState.isAISpeaking) → \(newState.isAISpeaking)")
      }

      if previousState.mode != newState.mode {
        print("   mode: \(previousState.mode) → \(newState.mode)")
      }

      if previousState.lastError != newState.lastError {
        print("   lastError: \(previousState.lastError ?? "nil") → \(newState.lastError ?? "nil")")
      }

      if previousState.connectionRetryCount != newState.connectionRetryCount {
        print(
          "   connectionRetryCount: \(previousState.connectionRetryCount) → \(newState.connectionRetryCount)"
        )
      }

      if previousState.audioLevel != newState.audioLevel {
        print("   audioLevel: \(previousState.audioLevel) → \(newState.audioLevel)")
      }
    #endif
  }
}

// MARK: - Testing Support
#if DEBUG
  extension VoiceChatStore {

    /// Устанавливает состояние напрямую (только для тестов)
    func setState(_ newState: VoiceChatState) {
      state = newState
    }

    /// Возвращает текущее состояние (для тестов)
    func getCurrentState() -> VoiceChatState {
      state
    }
  }
#endif
