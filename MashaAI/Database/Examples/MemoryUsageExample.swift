//import Foundation
//
//// MARK: - Example Usage of Memory System
//
//class MemoryUsageExample {
//    private let memoryController: MemoryController
//
//    init() {
//        // Создание MemoryController с настройками по умолчанию
//        self.memoryController = MemoryController.makeDefault()
//    }
//
//    // MARK: - Example Methods
//
//    func demonstrateBasicUsage() async {
//        do {
//            // Добавление сообщения пользователя
//            try await memoryController.addUserMessage("Привет, как дела?")
//
//            // Добавление ответа AI
//            try await memoryController.addAIMessage("Привет! У меня все отлично, спасибо за вопрос!")
//
//            // Получение всех воспоминаний
//            let allMemories = await memoryController.getMemories()
//            print("Всего воспоминаний: \(allMemories.count)")
//
//            // Получение последних 5 воспоминаний
//            let recentMemories = await memoryController.getRecentMemories(limit: 5)
//            print("Последние воспоминания:")
//            recentMemories.forEach { memory in
//                print("[\(memory.timestamp)] \(memory.formattedContent)")
//            }
//
//        } catch {
//            print("Ошибка при работе с памятью: \(error)")
//        }
//    }
//
//    func demonstrateDialogue() async {
//        do {
//            // Добавление диалога одним вызовом
//            try await memoryController.addDialogue(
//                userMessage: "Какая сегодня погода?",
//                aiMessage: "Сегодня солнечно и тепло, отличная погода для прогулки!"
//            )
//
//            // Получение контекста для AI
//            let context = await memoryController.getContextForAI(maxMessages: 10)
//            print("Контекст для AI:\n\(context)")
//
//        } catch {
//            print("Ошибка при создании диалога: \(error)")
//        }
//    }
//
//    func demonstrateReactiveUpdates() {
//        // Подписка на изменения в памяти
//        memoryController.observeMemories()
//            .sink { memories in
//                print("Обновление памяти! Всего воспоминаний: \(memories.count)")
//
//                // Последние 3 воспоминания
//                let recent = Array(memories.suffix(3))
//                recent.forEach { memory in
//                    print("- \(memory.formattedContent)")
//                }
//            }
//    }
//
//    func demonstrateFormattedOutput() {
//        // Использование отформатированных воспоминаний для UI
//        let formattedMemories = memoryController.formattedMemories
//        print("Отформатированные воспоминания для UI:")
//        formattedMemories.forEach { formatted in
//            print("• \(formatted)")
//        }
//    }
//
//    func clearAllMemories() async {
//        do {
//            try await memoryController.clearMemories()
//            print("Все воспоминания очищены")
//        } catch {
//            print("Ошибка при очистке памяти: \(error)")
//        }
//    }
//}
