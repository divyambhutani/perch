import AppKit

struct SpriteFrameProvider {
    func image(named name: String) -> NSImage? {
        let path = (name as NSString).deletingPathExtension
        let resource = URL(fileURLWithPath: path).lastPathComponent
        let subdirectoryPath = URL(fileURLWithPath: path).deletingLastPathComponent().path
        let subdirectory = subdirectoryPath == "." ? nil : subdirectoryPath

        guard let url = PerchBundle.resources.url(
            forResource: resource,
            withExtension: "png",
            subdirectory: subdirectory
        ) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}
