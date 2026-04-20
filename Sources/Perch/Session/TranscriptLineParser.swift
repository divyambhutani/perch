import Foundation

enum TranscriptLineParser {
    static func apply(line: String, into turn: inout LiveTurn, now: Date = .now) {
        guard let data = line.data(using: .utf8) else { return }
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return }

        let type = obj["type"] as? String
        guard type == "user" || type == "assistant" else { return }

        let timestamp = (obj["timestamp"] as? String).flatMap(Self.parseTimestamp) ?? now

        guard let message = obj["message"] as? [String: Any],
              let content = message["content"] else { return }

        if let text = content as? String {
            if type == "user", !text.isEmpty {
                recordUserPrompt(text: text, at: timestamp, turn: &turn)
            }
            return
        }

        guard let blocks = content as? [[String: Any]] else { return }

        for block in blocks {
            guard let btype = block["type"] as? String else { continue }
            switch btype {
            case "text" where type == "user":
                if let raw = block["text"] as? String, !raw.isEmpty {
                    recordUserPrompt(text: raw, at: timestamp, turn: &turn)
                }
            case "tool_use" where type == "assistant":
                turn.activeToolName = block["name"] as? String
                turn.activeToolPreview = preview(input: block["input"])
            case "tool_result":
                turn.activeToolName = nil
                turn.activeToolPreview = nil
            default:
                break
            }
        }
    }

    private static func recordUserPrompt(text: String, at timestamp: Date, turn: inout LiveTurn) {
        turn.lastUserPrompt = text
        turn.turnStartedAt = timestamp
        turn.activeToolName = nil
        turn.activeToolPreview = nil
    }

    private static func preview(input: Any?) -> String? {
        guard let dict = input as? [String: Any] else { return nil }
        if let command = dict["command"] as? String { return truncate(command) }
        if let filePath = dict["file_path"] as? String {
            return truncate(URL(fileURLWithPath: filePath).lastPathComponent)
        }
        if let pattern = dict["pattern"] as? String { return truncate(pattern) }
        if let prompt = dict["prompt"] as? String { return truncate(prompt) }
        if let description = dict["description"] as? String { return truncate(description) }
        return nil
    }

    private static func truncate(_ s: String, limit: Int = 60) -> String {
        guard s.count > limit else { return s }
        return String(s.prefix(limit - 1)) + "…"
    }

    private static func parseTimestamp(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        return basic.date(from: raw)
    }
}
