import ElevenLabsSDK
import Foundation

// MARK: - VoiceChatReducer
/// Редюсер для обработки действий и изменения состояния VoiceChat
/// Все изменения состояния происходят только здесь, обеспечивая предсказуемость
struct VoiceChatReducer {

  // MARK: - Main Reducer Function
  /// Основная функция редюсера, обрабатывает действия и возвращает новое состояние
  /// - Parameters:
  ///   - state: Текущее состояние
  ///   - action: Действие для обработки
  /// - Returns: Новое состояние после применения действия
  static func reduce(_ state: VoiceChatState, _ action: VoiceChatAction) -> VoiceChatState {
    var newState = state

    switch action {

    // MARK: - View Lifecycle
    case .viewDidAppear:
      // При появлении view остается в состоянии appearing
      // Переход к loading происходит через loadingCompleted
      break

    case .viewDidDisappear:
      // При исчезновении view сбрасываем все состояния
      newState = VoiceChatState()  // Полный сброс к начальному состоянию

    case .loadingCompleted:
      // Переход от appearing к loading
      if newState.viewState == .appearing {
        newState.viewState = .loading
      }

    // MARK: - User Actions
    case .toggleConversation:
      // Переключение разговора в зависимости от текущего состояния
      if newState.isConnected {
        newState = handleStopConversation(newState)
      } else if !newState.isConnecting {
        newState = handleStartConversation(newState)
      }

    case .startConversation:
      newState = handleStartConversation(newState)

    case .stopConversation:
      newState = handleStopConversation(newState)

    // MARK: - Connection Management
    case .connectionStarted:
      newState.isConnecting = true
      newState.lastError = nil

    case .connectionEstablished(let conversationId):
      print("✅ Connected successfully with ID: \(conversationId)")
      newState.status = .connected
      newState.isConnecting = false
      newState.viewState = .connected
      newState.connectionRetryCount = 0
      newState.lastError = nil

    case .connectionDisconnected:
      print("🔌 Disconnected")
      newState = handleDisconnection(newState)

    case .connectionError(let message):
      print("❌ Error: \(message)")
      newState = handleConnectionError(newState, message: message)

    case .incrementRetryCount:
      newState.connectionRetryCount += 1

    case .resetRetryCount:
      newState.connectionRetryCount = 0

    case .retryConnection:
      // Логика повторного подключения обрабатывается в Interactor
      newState.lastError = nil

    // MARK: - Audio State Changes
    case .statusChanged(let status):
      print("📊 Status changed: \(status)")
      newState.status = status
      if status == .disconnected {
        newState.isConnecting = false
      }

    case .modeChanged(let fromMode, let toMode):
      print("🎤 Mode changed: \(fromMode) → \(toMode)")
      newState.mode = toMode
      newState = handleAISpeakingStateChange(newState, from: fromMode, to: toMode)

    case .volumeUpdated(let volume):
      newState.audioLevel = max(0, min(1, volume))

    case .messageReceived(let message, let role):
      // Сохранение сообщения обрабатывается в Interactor
      // Здесь можно добавить логику для UI состояния, если необходимо
      break

    // MARK: - AI Speaking State
    case .aiStartedSpeaking:
      newState.isAISpeaking = true

    case .aiStoppedSpeaking:
      newState.isAISpeaking = false

    // MARK: - Error Handling
    case .clearError:
      newState.lastError = nil

    case .setErrorState:
      if newState.lastError != nil {
        newState.viewState = .error
      }

    case .autoReturnToLoading:
      newState.viewState = .loading

    // MARK: - Debug Actions
    case .simulateAISpeaking:
      print("🧪 Simulating AI speaking transition")
      newState.mode = .speaking
      newState.isAISpeaking = true

    case .simulateAIListening:
      newState.mode = .listening
      newState.isAISpeaking = false
    }

    return newState
  }
}

// MARK: - Private Helper Functions
extension VoiceChatReducer {

  /// Обрабатывает начало разговора
  fileprivate static func handleStartConversation(_ state: VoiceChatState) -> VoiceChatState {
    guard !state.isConnecting else {
      print("⚠️ Connection already in progress, skipping...")
      return state
    }

    var newState = state
    newState.lastError = nil
    newState.connectionRetryCount = 0
    newState.isConnecting = true

    return newState
  }

  /// Обрабатывает остановку разговора
  fileprivate static func handleStopConversation(_ state: VoiceChatState) -> VoiceChatState {
    print("🧹 Cleaning up conversation...")

    var newState = state
    newState.status = .disconnected
    newState.isConnecting = false
    newState.audioLevel = 0.0
    newState.mode = .listening
    newState.isAISpeaking = false
    newState.viewState = .loading

    return newState
  }

  /// Обрабатывает отключение
  fileprivate static func handleDisconnection(_ state: VoiceChatState) -> VoiceChatState {
    var newState = state

    if state.status == .connected {
      // Неожиданное отключение
      newState.lastError = "Connection lost unexpectedly"
    }

    newState = handleStopConversation(newState)

    return newState
  }

  /// Обрабатывает ошибки подключения
  fileprivate static func handleConnectionError(
    _ state: VoiceChatState,
    message: String
  ) -> VoiceChatState {
    var newState = state

    // Игнорируем ошибки коррекции агента
    if isAgentCorrectionError(message) {
      print("ℹ️ Agent response correction detected - this is normal when interrupting")
      return newState
    }

    newState.lastError = message

    // Проверяем возможность повтора
    if shouldRetryConnection(errorMessage: message) && !state.hasReachedMaxRetries {
      newState.connectionRetryCount += 1
      print("🔄 Will retry connection (\(newState.connectionRetryCount)/2) in 3 seconds...")
      // Логика повтора обрабатывается в Interactor
    } else {
      print("💥 Max retries reached or non-retryable error")
      newState = handleStopConversation(newState)
    }

    return newState
  }

  /// Обрабатывает изменения состояния речи AI
  fileprivate static func handleAISpeakingStateChange(
    _ state: VoiceChatState,
    from previousMode: ElevenLabsSDK.Mode,
    to newMode: ElevenLabsSDK.Mode
  ) -> VoiceChatState {
    var newState = state

    switch (previousMode, newMode) {
    case (.listening, .speaking):
      newState.isAISpeaking = true

    case (.speaking, .listening):
      newState.isAISpeaking = false

    case (.listening, .listening):
      print("🔄 Still listening...")

    case (.speaking, .speaking):
      print("🔄 Still speaking...")

    default:
      print("🔄 Other transition: \(previousMode) → \(newMode)")

      // Обработка других переходов в .speaking
      if newMode == .speaking && !newState.isAISpeaking {
        newState.isAISpeaking = true
      }

      // Обработка других переходов в .listening
      if newMode == .listening && newState.isAISpeaking {
        newState.isAISpeaking = false
      }
    }

    print("📊 After transition isAISpeaking: \(newState.isAISpeaking)")

    return newState
  }

  /// Проверяет, является ли ошибка коррекцией агента
  fileprivate static func isAgentCorrectionError(_ errorMessage: String) -> Bool {
    let correctionIndicators = [
      "agent_response_correction",
      "Unknown message type",
      "corrected_agent_response",
      "original_agent_response",
    ]

    let errorLower = errorMessage.lowercased()
    return correctionIndicators.contains { errorLower.contains($0.lowercased()) }
  }

  /// Определяет, стоит ли повторять подключение при данной ошибке
  fileprivate static func shouldRetryConnection(errorMessage: String) -> Bool {
    let retryableErrors = [
      "Socket is not connected",
      "WebSocket error",
      "Connection failed",
      "Network error",
      "timeout",
    ]

    let nonRetryableErrors = [
      "unauthorized",
      "forbidden",
      "invalid agent",
      "rate limit",
      "agent_response_correction",
      "Unknown message type",
    ]

    let errorLower = errorMessage.lowercased()

    // Сначала проверяем не-повторяемые ошибки
    if nonRetryableErrors.contains(where: { errorLower.contains($0) }) {
      return false
    }

    // Затем проверяем повторяемые
    return retryableErrors.contains { errorLower.contains($0) }
  }
}
