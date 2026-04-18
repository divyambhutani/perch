import SwiftUI

struct PermissionDiffView: View {
    let request: PermissionRequest

    var body: some View {
        ScrollView {
            Text(request.diffPreview.isEmpty ? PerchStrings.noDiffPreview() : request.diffPreview)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 120)
    }
}
