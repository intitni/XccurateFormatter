import SwiftUI

struct Card<Content: View>: View {
    var title: String
    var link: URL
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(title)
                Spacer()
                Link(destination: link) {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                }
                .onHover { inside in
                    if inside {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }.font(.headline)
            content()
        }
        .padding(.all, 12)
        .background(Color(nsColor: .controlBackgroundColor))
        .border(Color(nsColor: .separatorColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 1)
    }
}
