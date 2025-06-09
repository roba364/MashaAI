import SwiftUI

struct ProfileView: View {
    @ObservedObject
    var viewModel: ProfileVM

    var body: some View {
        VStack {
            Text("Profile View")

            Button {
                viewModel.onDetails()
            } label: {
                Text("Profile Details")
            }
        }
    }
}
