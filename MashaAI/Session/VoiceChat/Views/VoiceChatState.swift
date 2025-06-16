import ElevenLabsSDK
import Foundation

// MARK: - VoiceChatState
/// Централизованное состояние для VoiceChat модуля
/// Содержит все данные, необходимые для отображения UI
struct VoiceChatState: Equatable {

  // MARK: - Nested Types
  enum ViewState: Equatable {
    case appearing
    case loading
    case connected
    case error
  }

  // MARK: - Connection State
  /// Статус подключения к ElevenLabs SDK
  var status: ElevenLabsSDK.Status = .disconnected

  /// Флаг процесса подключения
  var isConnecting: Bool = false

  /// Последняя ошибка подключения
  var lastError: String? = nil

  /// Количество попыток переподключения
  var connectionRetryCount: Int = 0

  // MARK: - Audio State
  /// Режим работы (listening/speaking)
  var mode: ElevenLabsSDK.Mode = .listening

  /// Уровень аудио сигнала (0.0 - 1.0)
  var audioLevel: Float = 0.0

  /// Флаг активной речи AI
  var isAISpeaking: Bool = false

  // MARK: - UI State
  /// Состояние отображения View
  var viewState: ViewState = .appearing

  // MARK: - Equatable Implementation
  static func == (lhs: VoiceChatState, rhs: VoiceChatState) -> Bool {
    return lhs.status == rhs.status && lhs.isConnecting == rhs.isConnecting
      && lhs.lastError == rhs.lastError && lhs.connectionRetryCount == rhs.connectionRetryCount
      && lhs.mode == rhs.mode && lhs.audioLevel == rhs.audioLevel
      && lhs.isAISpeaking == rhs.isAISpeaking && lhs.viewState == rhs.viewState
  }
}

// MARK: - Computed Properties
extension VoiceChatState {
  /// Проверяет, подключен ли к голосовому чату
  var isConnected: Bool {
    status == .connected
  }

  /// Проверяет, есть ли активная ошибка
  var hasError: Bool {
    lastError != nil
  }

  /// Проверяет, достигнут ли лимит попыток переподключения
  var hasReachedMaxRetries: Bool {
    connectionRetryCount >= 2
  }
}
