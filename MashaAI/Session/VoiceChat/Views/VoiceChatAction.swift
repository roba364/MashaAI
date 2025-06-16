import ElevenLabsSDK
import Foundation

// MARK: - VoiceChatAction
/// Все возможные действия в VoiceChat модуле
/// Представляют намерения пользователя и системные события
enum VoiceChatAction: Equatable {

  // MARK: - View Lifecycle Actions
  /// View появился на экране
  case viewDidAppear

  /// View исчез с экрана
  case viewDidDisappear

  /// Завершена загрузка и можно показать основной интерфейс
  case loadingCompleted

  // MARK: - User Actions
  /// Пользователь нажал кнопку начала/остановки разговора
  case toggleConversation

  /// Пользователь хочет начать разговор
  case startConversation

  /// Пользователь хочет остановить разговор
  case stopConversation

  // MARK: - Connection Actions
  /// Начинается процесс подключения
  case connectionStarted

  /// Подключение установлено успешно
  case connectionEstablished(conversationId: String)

  /// Подключение разорвано
  case connectionDisconnected

  /// Произошла ошибка подключения
  case connectionError(message: String)

  /// Увеличить счетчик попыток переподключения
  case incrementRetryCount

  /// Сбросить счетчик попыток переподключения
  case resetRetryCount

  /// Попытка переподключения
  case retryConnection

  // MARK: - Audio Actions
  /// Изменился статус подключения
  case statusChanged(ElevenLabsSDK.Status)

  /// Изменился режим работы (listening/speaking)
  case modeChanged(from: ElevenLabsSDK.Mode, to: ElevenLabsSDK.Mode)

  /// Обновился уровень громкости
  case volumeUpdated(Float)

  /// Получено сообщение от AI
  case messageReceived(message: String, role: ElevenLabsSDK.Role)

  // MARK: - AI Speaking State Actions
  /// AI начал говорить
  case aiStartedSpeaking

  /// AI закончил говорить
  case aiStoppedSpeaking

  // MARK: - Error Handling Actions
  /// Очистить последнюю ошибку
  case clearError

  /// Установить состояние ошибки
  case setErrorState

  /// Автоматически вернуться к состоянию загрузки после ошибки
  case autoReturnToLoading

  // MARK: - Debug Actions (для тестирования)
  /// Симуляция речи AI (debug)
  case simulateAISpeaking

  /// Симуляция прослушивания AI (debug)
  case simulateAIListening

  // MARK: - Equatable Implementation
  static func == (lhs: VoiceChatAction, rhs: VoiceChatAction) -> Bool {
    switch (lhs, rhs) {
    case (.viewDidAppear, .viewDidAppear),
      (.viewDidDisappear, .viewDidDisappear),
      (.loadingCompleted, .loadingCompleted),
      (.toggleConversation, .toggleConversation),
      (.startConversation, .startConversation),
      (.stopConversation, .stopConversation),
      (.connectionStarted, .connectionStarted),
      (.connectionDisconnected, .connectionDisconnected),
      (.incrementRetryCount, .incrementRetryCount),
      (.resetRetryCount, .resetRetryCount),
      (.retryConnection, .retryConnection),
      (.aiStartedSpeaking, .aiStartedSpeaking),
      (.aiStoppedSpeaking, .aiStoppedSpeaking),
      (.clearError, .clearError),
      (.setErrorState, .setErrorState),
      (.autoReturnToLoading, .autoReturnToLoading),
      (.simulateAISpeaking, .simulateAISpeaking),
      (.simulateAIListening, .simulateAIListening):
      return true

    case let (.connectionEstablished(lhsId), .connectionEstablished(rhsId)):
      return lhsId == rhsId

    case let (.connectionError(lhsMsg), .connectionError(rhsMsg)):
      return lhsMsg == rhsMsg

    case let (.statusChanged(lhsStatus), .statusChanged(rhsStatus)):
      return lhsStatus == rhsStatus

    case let (.modeChanged(lhsFrom, lhsTo), .modeChanged(rhsFrom, rhsTo)):
      return lhsFrom == rhsFrom && lhsTo == rhsTo

    case let (.volumeUpdated(lhsVolume), .volumeUpdated(rhsVolume)):
      return lhsVolume == rhsVolume

    case let (.messageReceived(lhsMsg, lhsRole), .messageReceived(rhsMsg, rhsRole)):
      return lhsMsg == rhsMsg && lhsRole == rhsRole

    default:
      return false
    }
  }
}

// MARK: - Action Categories
extension VoiceChatAction {
  /// Проверяет, является ли действие связанным с подключением
  var isConnectionAction: Bool {
    switch self {
    case .connectionStarted, .connectionEstablished, .connectionDisconnected,
      .connectionError, .incrementRetryCount, .resetRetryCount, .retryConnection:
      return true
    default:
      return false
    }
  }

  /// Проверяет, является ли действие связанным с аудио
  var isAudioAction: Bool {
    switch self {
    case .statusChanged, .modeChanged, .volumeUpdated, .messageReceived,
      .aiStartedSpeaking, .aiStoppedSpeaking:
      return true
    default:
      return false
    }
  }

  /// Проверяет, является ли действие пользовательским
  var isUserAction: Bool {
    switch self {
    case .toggleConversation, .startConversation, .stopConversation:
      return true
    default:
      return false
    }
  }
}
