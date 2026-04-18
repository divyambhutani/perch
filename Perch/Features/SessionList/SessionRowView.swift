import SwiftUI

struct SessionRowView: View {
    let session: SessionSnapshot

    var body: some View {
        HStack {
            Text(session.title)
            Spacer()
            StatusBadge(label: session.familiarState.rawValue.capitalized)
        }
        .font(.caption)
    }
}
