import Foundation
import UIKit

public enum SceneDelegateEvent: Broadcasting {
    case sceneWillConnect(UIScene.ConnectionOptions)
    case sceneDidBecomeActive
    case sceneOpenURL(OpenURLInfo)
    case performActionFor(UIApplicationShortcutItem)
    case userActivity(NSUserActivity)
}

public enum AppDelegateEvent: Broadcasting {
    case didFinishLaunchingWithOptions
}

public struct OpenURLInfo {
    let url: URL
    var sourceApplication: String?
    var customScheme: Bool

    public init(
        url: URL,
        sourceApplication: String? = nil,
        customScheme: Bool = false
    ) {
        self.url = url
        self.sourceApplication = sourceApplication
        self.customScheme = customScheme
    }
}
