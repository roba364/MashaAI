# VoiceChat UDF Architecture

## Краткий обзор

VoiceChat модуль реализует **Unidirectional Data Flow (UDF)** архитектуру для предсказуемого управления состоянием и улучшенной тестируемости.

## Быстрый старт

### Инициализация

```swift
// В родительском View или Scene
let memoryController = MemoryController()
let viewModel = VoiceChatVM(memoryController: memoryController)

VoiceChatView(viewModel: viewModel)
```

### Основные компоненты

```swift
// 1. State - единственный источник истины
struct VoiceChatState {
    var status: ElevenLabsSDK.Status = .disconnected
    var isConnecting: Bool = false
    var isAISpeaking: Bool = false
    var viewState: ViewState = .appearing
}

// 2. Actions - все возможные действия
enum VoiceChatAction {
    case startConversation
    case connectionEstablished(String)
    case modeChanged(from: Mode, to: Mode)
}

// 3. Store - центральный координатор
store.dispatch(.startConversation) // Единственный способ изменить состояние
```

## Поток данных

```
User Input → Action → Reducer → New State → UI Update
     ↓
Side Effects → Interactor → Action → Store
```

## Примеры использования

### Начать разговор

```swift
// В View
Button("Start") {
    viewModel.beginConversation()
}

// Внутри: View → ViewModel → Store → Interactor → ElevenLabs SDK
```

### Отслеживание состояния AI

```swift
// Автоматически обновляется при изменении состояния
if viewModel.isAISpeaking {
    Text("AI говорит...")
        .foregroundColor(.green)
}
```

### Обработка ошибок

```swift
// Централизованная обработка в Reducer
if let error = viewModel.lastError {
    ErrorView(message: error)
}
```

## Преимущества

- ✅ **Предсказуемость**: Все изменения в одном месте
- ✅ **Тестируемость**: Pure функции легко тестировать
- ✅ **Отладка**: Полное логирование всех действий
- ✅ **Реактивность**: Автоматические обновления UI
- ✅ **Разделение ответственности**: Четкие границы компонентов

## Файловая структура

```
VoiceChat/
├── Views/
│   ├── VoiceChatView.swift           # SwiftUI View
│   ├── VoiceChatVM.swift             # ViewModel (адаптер)
│   ├── VoiceChatState.swift          # Состояние
│   ├── VoiceChatAction.swift         # Действия
│   ├── VoiceChatReducer.swift        # Логика изменения состояния
│   ├── VoiceChatStore.swift          # Центральный координатор
│   └── VoiceChatInteractor.swift     # Side effects
└── Documentation/
    └── UDF_Architecture.md          # Подробная документация
```

## Миграция от MVVM

Публичный API остался неизменным - существующий код продолжает работать без изменений.

### Было:

```swift
@Published var status: Status = .disconnected

func startConnection() {
    self.status = .connecting  // Прямая мутация
}
```

### Стало:

```swift
var status: Status { store.status }  // Readonly property

func startConnection() {
    store.dispatch(.connectionStarted)  // Через actions
}
```

Полная документация: [UDF_Architecture.md](Documentation/UDF_Architecture.md)
