import Foundation
import UIKit

public protocol MailSenderControlling {
    func sendMail(to email: String, subject: String, body: String)
}

protocol MailAgent {
    var scheme: URL { get }
    func url(for email: String, subject: String, body: String) -> URL?
}

public final class MailSenderController: MailSenderControlling {
    private let mailAgents: [MailAgent] = [
        GmailMailAgent(), OutlookMailAgent(), YahooMailAgent(), SparkMailAgent(), DefaultMailAgent()
    ]

    public init() {}

    public func sendMail(to email: String, subject: String, body: String) {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        let availableMailAgent = mailAgents.first { UIApplication.shared.canOpenURL($0.scheme) }

        if let url = availableMailAgent?.url(for: email, subject: subjectEncoded, body: bodyEncoded) {
            UIApplication.shared.open(url)
        }
    }
}

struct GmailMailAgent: MailAgent {
    var scheme: URL { URL(string: "googlegmail://")! }

    func url(for email: String, subject: String, body: String) -> URL? {
        URL(string: "googlegmail://co?to=\(email)&subject=\(subject)&body=\(body)")
    }
}

struct OutlookMailAgent: MailAgent {
    var scheme: URL { URL(string: "ms-outlook://")! }

    func url(for email: String, subject: String, body: String) -> URL? {
        URL(string: "ms-outlook://compose?to=\(email)&subject=\(subject)&body=\(body)")
    }
}

struct YahooMailAgent: MailAgent {
    var scheme: URL { URL(string: "ymail://")! }

    func url(for email: String, subject: String, body: String) -> URL? {
        URL(string: "ymail://mail/compose?to=\(email)&subject=\(subject)&body=\(body)")
    }
}

struct SparkMailAgent: MailAgent {
    var scheme: URL { URL(string: "readdle-spark://")! }

    func url(for email: String, subject: String, body: String) -> URL? {
        URL(string: "readdle-spark://compose?recipient=\(email)&subject=\(subject)&body=\(body)")
    }
}

struct DefaultMailAgent: MailAgent {
    var scheme: URL { URL(string: "mailto:")! }

    func url(for email: String, subject: String, body: String) -> URL? {
        URL(string: "mailto:\(email)?subject=\(subject)&body=\(body)")
    }
}
