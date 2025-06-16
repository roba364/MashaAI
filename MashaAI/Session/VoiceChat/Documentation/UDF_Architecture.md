# UDF Architecture для VoiceChat модуля

## Обзор архитектуры

VoiceChat модуль реализует **UDF (Unidirectional Data Flow)** архитектуру для обеспечения предсказуемого и тестируемого управления состоянием.

### Диаграмма потока данных

```
┌─────────────┐    Actions    ┌──────────────┐    New State    ┌─────────────┐
│             │ ─────────────▶│              │ ─────────────▶ │             │
│    View     │               │    Store     │                │   Reducer   │
│             │◀─────────────  │              │◀─────────────  │             │
└─────────────┘    State      └──────────────┘    Current     └─────────────┘
       │                             │            State              │
       │                             │                               │
       │ Side Effects               │ Dispatch                      │ Pure
       │                             │ Actions                       │ Functions
       ▼                             ▼                               │
┌─────────────┐              ┌──────────────┐                       │
│             │              │              │                       │
│ Interactor  │              │    State     │                       │
│             │              │              │                       │
└─────────────┘              └──────────────┘◀──────────────────────┘
```

## Компоненты архитектуры

### 1. VoiceChatState (State)

**Файл:** `VoiceChatState.swift`

**Назначение:** Единственный источник истины для всего состояния VoiceChat модуля.

```swift
struct VoiceChatState: Equatable {
    // Connection State
    var status: ElevenLabsSDK.Status = .disconnected
    var isConnecting: Bool = false
    var lastError: String? = nil
    var connectionRetryCount: Int = 0

    // Audio State
    var mode: ElevenLabsSDK.Mode = .listening
    var audioLevel: Float = 0.0
    var isAISpeaking: Bool = false

    // UI State
    var viewState: ViewState = .appearing
}
```

**Принципы:**

- Immutable структура
- Реализует `Equatable` для оптимизации перерисовки UI
- Содержит computed properties для удобного доступа
- Все изменения происходят только через создание новых экземпляров

### 2. VoiceChatAction (Actions)

**Файл:** `VoiceChatAction.swift`

**Назначение:** Описывает все возможные действия в системе.

```swift
enum VoiceChatAction: Equatable {
    // View Lifecycle
    case viewDidAppear
    case viewDidDisappear
    case loadingCompleted

    // User Actions
    case toggleConversation
    case startConversation
    case stopConversation

    // Connection Actions
    case connectionStarted
    case connectionEstablished(conversationId: String)
    case connectionDisconnected
    case connectionError(message: String, code: Int?)

    // Audio Actions
    case statusChanged(ElevenLabsSDK.Status)
    case modeChanged(from: ElevenLabsSDK.Mode, to: ElevenLabsSDK.Mode)
    case volumeUpdated(Float)

    // AI Speaking State
    case aiStartedSpeaking
    case aiStoppedSpeaking
}
```

**Принципы:**

- Enum с associated values для передачи данных
- Implements `Equatable` для сравнения действий
- Категоризированы по типам для лучшей организации
- Покрывают все возможные события в системе

### 3. VoiceChatReducer (Reducer)

**Файл:** `VoiceChatReducer.swift`

**Назначение:** Pure функции для обработки действий и создания нового состояния.

```swift
struct VoiceChatReducer {
    static func reduce(_ state: VoiceChatState, _ action: VoiceChatAction) -> VoiceChatState {
        var newState = state

        switch action {
        case .connectionEstablished(let conversationId):
            newState.status = .connected
            newState.isConnecting = false
            newState.viewState = .connected
            newState.connectionRetryCount = 0
            newState.lastError = nil

        // ... другие cases
        }

        return newState
    }
}
```

**Принципы:**

- **Pure функции** - нет side effects
- **Immutable** - возвращают новое состояние вместо мутации
- **Предсказуемые** - один и тот же input всегда дает один и тот же output
- **Тестируемые** - легко покрыть unit тестами

### 4. VoiceChatStore (Store)

**Файл:** `VoiceChatStore.swift`

**Назначение:** Центральный координатор состояния, связывающий все компоненты.

```swift
@MainActor
final class VoiceChatStore: ObservableObject {
    @Published private(set) var state = VoiceChatState()

    func dispatch(_ action: VoiceChatAction) {
        let newState = reducer(state, action)
        if newState != state {
            state = newState
        }
    }
}
```

**Возможности:**

- **Реактивность** через `@Published` и Combine
- **Логирование** изменений состояния в Debug режиме
- **Convenience accessors** для упрощения доступа к состоянию
- **Publishers** для специфических частей состояния

### 5. VoiceChatInteractor (Side Effects)

**Файл:** `VoiceChatInteractor.swift`

**Назначение:** Обработка асинхронных операций и взаимодействие с внешними сервисами.

```swift
final class VoiceChatInteractor: ObservableObject {
    private let memoryController: MemoryControlling
    private let store: VoiceChatStore

    func startConversation() {
        store.dispatch(.connectionStarted)

        connectionTask = Task {
            await performConnection(agent: Agent.masha)
        }
    }
}
```

**Обязанности:**

- **Async операции** (сетевые запросы, Task management)
- **Взаимодействие с SDK** (ElevenLabs, Memory Controller)
- **Side effects** (таймеры, уведомления)
- **Lifecycle management** (cleanup, resource management)

### 6. VoiceChatVM (ViewModel)

**Файл:** `VoiceChatVM.swift`

**Назначение:** Адаптер между UDF архитектурой и SwiftUI View.

```swift
final class VoiceChatVM: ObservableObject {
    private let store: VoiceChatStore
    private let interactor: VoiceChatInteractor

    // Passthrough properties
    var viewState: VoiceChatState.ViewState { store.viewState }
    var isAISpeaking: Bool { store.isAISpeaking }

    // Action methods
    func beginConversation() {
        store.dispatch(.toggleConversation)
        // Side effect через Interactor
    }
}
```

## Поток данных

### 1. User Action → Store

```
User taps button → View calls viewModel.beginConversation()
                → store.dispatch(.toggleConversation)
                → Reducer creates new state
                → Store publishes new state
                → View updates automatically
```

### 2. Side Effect → Store

```
Network callback → Interactor receives onConnect
                → store.dispatch(.connectionEstablished)
                → Reducer updates connection state
                → Store publishes new state
                → View shows connected UI
```

### 3. State Change → View

```
State change → Store @Published triggers
            → SwiftUI observes changes
            → View re-renders with new state
```

## Преимущества UDF архитектуры

### 1. **Предсказуемость**

- Все изменения состояния происходят в одном месте (Reducer)
- Легко понять, как состояние изменяется
- Debugging упрощен благодаря логированию actions

### 2. **Тестируемость**

- Reducer - pure функции, легко тестировать
- State - простые структуры данных
- Можно мокать Store для изоляции компонентов

### 3. **Разделение ответственности**

- View отвечает только за UI
- Reducer только за логику состояния
- Interactor только за side effects
- Store только за координацию

### 4. **Реактивность**

- Автоматические обновления UI при изменении состояния
- Combine publishers для подписки на определенные изменения
- SwiftUI интеграция через @ObservableObject

### 5. **Отладка**

- Все действия логируются
- Можно отследить последовательность действий
- Time-travel debugging возможен

## Сравнение с предыдущей архитектурой

### Было (MVVM):

```swift
// Прямое изменение состояния в разных местах
callbacks.onConnect = { [weak self] in
    self?.status = .connected          // ❌ Мутация
    self?.isConnecting = false         // ❌ Мутация
    self?.viewState = .connected       // ❌ Мутация
}
```

### Стало (UDF):

```swift
// Все изменения через единый поток
callbacks.onConnect = { [weak self] conversationId in
    self?.store.dispatch(.connectionEstablished(conversationId: conversationId))
}

// В Reducer:
case .connectionEstablished(let conversationId):
    newState.status = .connected       // ✅ Immutable creation
    newState.isConnecting = false      // ✅ Centralized logic
    newState.viewState = .connected    // ✅ Predictable changes
```

## Правила использования

### ✅ DO:

- Всегда используйте `store.dispatch()` для изменения состояния
- Обрабатывайте side effects в Interactor
- Делайте Reducer функции pure (без side effects)
- Используйте computed properties в State для derived данных

### ❌ DON'T:

- Не изменяйте состояние напрямую в View или ViewModel
- Не выполняйте async операции в Reducer
- Не держите mutable состояние в разных местах
- Не игнорируйте принцип единого источника истины

## Тестирование

### Тестирование Reducer:

```swift
func testConnectionEstablished() {
    let initialState = VoiceChatState()
    let action = VoiceChatAction.connectionEstablished(conversationId: "test")

    let newState = VoiceChatReducer.reduce(initialState, action)

    XCTAssertEqual(newState.status, .connected)
    XCTAssertFalse(newState.isConnecting)
    XCTAssertEqual(newState.viewState, .connected)
}
```

### Тестирование Store:

```swift
func testStoreDispatch() {
    let store = VoiceChatStore()

    store.dispatch(.connectionStarted)

    XCTAssertTrue(store.state.isConnecting)
    XCTAssertNil(store.state.lastError)
}
```

## Миграция

Миграция от старой MVVM архитектуры к UDF прошла с сохранением всего поведения:

1. **State consolidation**: Все @Published свойства → VoiceChatState
2. **Action extraction**: Все прямые изменения → VoiceChatAction
3. **Logic centralization**: Вся бизнес-логика → VoiceChatReducer
4. **Side effect isolation**: Async операции → VoiceChatInteractor
5. **Interface preservation**: Public API остался неизменным

Результат: **100% сохранение поведения** при улучшенной архитектуре.
