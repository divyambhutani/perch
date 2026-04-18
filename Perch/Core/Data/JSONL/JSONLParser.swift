import Foundation

struct JSONLParser {
    func parse(contents: String) throws -> [TranscriptEvent] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try contents
            .split(whereSeparator: \.isNewline)
            .filter { !$0.isEmpty }
            .map { line in
                let data = Data(String(line).utf8)
                do {
                    return try decoder.decode(TranscriptEvent.self, from: data)
                } catch {
                    throw JSONLError.malformedLine(String(line))
                }
            }
    }
}
