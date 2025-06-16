import Combine
import ElevenLabsSDK
import Foundation

// MARK: - VoiceChatVM
/// ViewModel для VoiceChat, реализующий UDF (Unidirectional Data Flow) архитектуру
///
/// **Архитектура UDF:**
/// ```
/// View → Action → Reducer → State → View
///   ↓                              ↑
/// Interactor ← Side Effects ←── Store
/// ```
///
/// **Компоненты:**
/// - **State**: VoiceChatState - единственный источник истины
/// - **Actions**: VoiceChatAction - все возможные действия
/// - **Reducer**: VoiceChatReducer - pure функции для изменения state
/// - **Store**: VoiceChatStore - центральный координатор
/// - **Interactor**: VoiceChatInteractor - обработка side effects

@MainActor
final class VoiceChatVM: ObservableObject {

  // MARK: - Dependencies (UDF Components)
  private let store: VoiceChatStore
  private let interactor: VoiceChatInteractor

  // MARK: - State Passthrough Properties
  /// Все свойства теперь берутся из централизованного State через Store
  /// Это обеспечивает единый источник истины (Single Source of Truth)

  var viewState: VoiceChatState.ViewState {
    store.viewState
  }

  var status: ElevenLabsSDK.Status {
    store.status
  }

  var isConnecting: Bool {
    store.isConnecting
  }

  var lastError: String? {
    store.lastError
  }

  var mode: ElevenLabsSDK.Mode {
    store.mode
  }

  var connectionRetryCount: Int {
    store.state.connectionRetryCount
  }

  var audioLevel: Float {
    store.audioLevel
  }

  var isAISpeaking: Bool {
    store.isAISpeaking
  }

  // MARK: - Published State (for SwiftUI binding)
  /// Store публикует изменения состояния, а ViewModel их проксирует
  @Published private var storeState: VoiceChatState = VoiceChatState()

  // MARK: - Private Properties
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  /// Инициализация с внедрением зависимостей
  init(memoryController: MemoryControlling) {
    // Создаем компоненты UDF архитектуры
    self.store = VoiceChatStore()
    self.interactor = VoiceChatInteractor(memoryController: memoryController, store: store)

    setupStateBinding()
  }

  // MARK: - Private Methods

  /// Настраивает привязку состояния Store к ViewModel
  /// Обеспечивает реактивность SwiftUI к изменениям в UDF Store
  private func setupStateBinding() {
    // Основная привязка состояния для SwiftUI
    store.$state
      .receive(on: DispatchQueue.main)
      .assign(to: \.storeState, on: self)
      .store(in: &cancellables)
  }

  // MARK: - Public Action Methods
  /// Все публичные методы теперь просто отправляют Actions в Store
  /// Это обеспечивает однонаправленный поток данных

  /// Обрабатывает появление View
  func onAppear() async {
    await store.dispatch(.viewDidAppear)
    await interactor.handleViewAppear()
  }

  /// Обрабатывает исчезновение View
  func onDisappear() {
    interactor.handleViewDisappear()
  }

  /// Начинает разговор с AI
  func beginConversation() {
    store.dispatch(.toggleConversation)

    // Запускаем side effect через Interactor
    if store.isConnected {
      interactor.stopConversation()
    } else {
      interactor.startConversation()
    }
  }

  /// Останавливает разговор
  func stopConversation() {
    interactor.stopConversation()
  }

  // MARK: - Debug Methods
  /// Debug методы для тестирования состояний

  func simulateAISpeaking() {
    interactor.simulateAISpeaking()
  }

  func simulateAIListening() {
    interactor.simulateAIListening()
  }
}

// MARK: - Legacy Support
/// Поддержка для обратной совместимости с существующим кодом
extension VoiceChatVM {

  /// Псевдоним для ViewState для обратной совместимости
  typealias ViewState = VoiceChatState.ViewState
}
