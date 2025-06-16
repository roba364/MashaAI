import Foundation

// MARK: - Domain Models

struct Memory: Equatable, Identifiable {
  let id: UUID
  let message: String
  let sender: MemorySender
  let timestamp: Date

  init(
    id: UUID = UUID(),
    message: String,
    sender: MemorySender,
    timestamp: Date = Date()
  ) {
    self.id = id
    self.message = message
    self.sender = sender
    self.timestamp = timestamp
  }
}

enum MemorySender: String, CaseIterable {
  case user = "user"
  case ai = "ai"

  var displayPrefix: String {
    switch self {
    case .user:
      return "Пользователь сказал"
    case .ai:
      return "Маша сказала"
    }
  }
}

extension Memory {
  var formattedContent: String {
    "\(sender.displayPrefix): \(message)"
  }
}
