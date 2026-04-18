import SwiftUI

struct SessionListView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(PerchStrings.sessionListTitle(tone: environment.sessionStore.currentFamiliar.tone))
                .font(.headline)

            ForEach(environment.sessionStore.sessions) { session in
                SessionRowView(session: session)
            }
        }
    }
}
