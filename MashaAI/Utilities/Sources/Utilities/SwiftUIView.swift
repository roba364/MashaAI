import SwiftUI
import MessageUI

public struct MailView: UIViewControllerRepresentable {

    @Binding
    var isShowing: Bool

    @Binding
    var result: Bool

    let email: String
    let subject: String
    private(set) var body: EmailBody?

    public init(
        isShowing: Binding<Bool>,
        result: Binding<Bool>,
        email: String,
        subject: String,
        body: EmailBody? = nil
    ) {
        self._isShowing = isShowing
        self._result = result
        self.email = email
        self.subject = subject
        self.body = body
    }

    public class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        @Binding var isShowing: Bool
        @Binding var result: Bool

        init(isShowing: Binding<Bool>,
             result: Binding<Bool>) {
            _isShowing = isShowing
            _result = result
        }

        public func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            guard isShowing else { return }

            defer {
                isShowing = false
            }
            guard error == nil else {
                self.result = false
                return
            }

            switch result {
            case .cancelled, .saved, .failed:
                self.result = false
            case .sent:
                self.result = true
            @unknown default:
                self.result = false
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing,
                           result: $result)
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([email])
        vc.setSubject(subject)
        if let body {
            vc.setMessageBody(body.body, isHTML: body.isHtml)
        }
        return vc
    }

    public func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailView>) {}
}

public struct EmailBody {
    let body: String
    let isHtml: Bool

    public init(body: String, isHtml: Bool) {
        self.body = body
        self.isHtml = isHtml
    }
}
