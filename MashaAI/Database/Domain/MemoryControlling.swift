import Combine
import Foundation

// MARK: - Memory Management Protocol

protocol MemoryControlling: AnyObject {
    /// Добавляет сообщение пользователя в память
    func addMemory(_ memory: Memory) async throws
    /// Получает все сохраненные воспоминания
    func getMemories() async -> [Memory]

    /// Получает последние N воспоминаний
    func getRecentMemories(limit: Int) async -> [Memory]

    /// Очищает все воспоминания
    func clearMemories() async throws

    /// Наблюдает за изменениями в памяти
    func observeMemories() -> AnyPublisher<[Memory], Never>

    /// Получает контекст для AI (последние N сообщений в виде строки)
    func getContextForAI(maxMessages: Int) async -> String
}
