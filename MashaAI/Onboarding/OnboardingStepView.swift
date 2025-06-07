import SwiftUI

struct OnboardingStepView: View {

    let text: String
    let onNext: () -> Void

    var body: some View {
        VStack {
            Button(action: onNext) {
                Text(text)
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    OnboardingStepView(text: "", onNext: {})
}
