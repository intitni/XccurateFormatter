import SwiftUI

struct Cheatsheet<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(.all, 4)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .unemphasizedSelectedTextBackgroundColor))
            .foregroundColor(Color(nsColor: .controlTextColor))
            .cornerRadius(4)
            .font(.caption)
    }
}
