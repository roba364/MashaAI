import Foundation
import Combine
import ElevenLabsSDK

final class VoiceChatVM: ObservableObject {
    
    private let config = ElevenLabsSDK.SessionConfig(agentId: "w63wjugjg9aztG1H9JDa")
    
    func onAppear() async {
        do {
            let conversation = try await ElevenLabsSDK.Conversation.startSession(config: config, callbacks: callbacks())
            // Use the conversation instance as needed
            print("---> connected")
        } catch {
            print("Failed to start conversation: \(error)")
        }
    }
    
    private func callbacks() -> ElevenLabsSDK.Callbacks {
        var callbacks = ElevenLabsSDK.Callbacks()
        callbacks.onConnect = { conversationId in
            print("---> Connected with ID: \(conversationId)")
        }
        callbacks.onMessage = { message, role in
            print("---> \(role.rawValue): \(message)")
        }
        callbacks.onError = { error, info in
            print("---> Error: \(error), Info: \(String(describing: info))")
        }
        callbacks.onStatusChange = { status in
            print("---> Status changed to: \(status.rawValue)")
        }
        callbacks.onModeChange = { mode in
            print("---> Mode changed to: \(mode.rawValue)")
        }
        
        return callbacks
    }
}
