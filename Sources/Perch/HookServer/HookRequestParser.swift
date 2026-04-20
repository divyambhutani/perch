import Foundation

struct HookRequestParser: Sendable {
    struct ParsedRequest: Equatable, Sendable {
        let method: String
        let path: String
        let headers: [String: String]
        let body: Data
    }

    enum ParseError: Error, Equatable, Sendable {
        case invalidUTF8Header
        case invalidRequestLine
        case invalidHeader
        case invalidContentLength
        case bodyExceedsMaxSize
    }

    enum Parse: Equatable, Sendable {
        case needMoreData
        case complete(ParsedRequest, consumed: Int)
    }

    static let maxBodyBytes = 1_048_576

    func parse(_ buffer: Data) throws -> Parse {
        let terminator = Data("\r\n\r\n".utf8)
        guard let terminatorRange = buffer.range(of: terminator) else {
            return .needMoreData
        }

        let headerSlice = buffer.prefix(terminatorRange.lowerBound)
        guard let headerText = String(data: headerSlice, encoding: .utf8) else {
            throw ParseError.invalidUTF8Header
        }

        let lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            throw ParseError.invalidRequestLine
        }
        let parts = requestLine.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count >= 2 else {
            throw ParseError.invalidRequestLine
        }
        let method = String(parts[0])
        let path = String(parts[1])

        var headers: [String: String] = [:]
        for rawLine in lines.dropFirst() where !rawLine.isEmpty {
            guard let colon = rawLine.firstIndex(of: ":") else {
                throw ParseError.invalidHeader
            }
            let key = rawLine[..<colon].lowercased()
            let value = rawLine[rawLine.index(after: colon)...]
                .trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }

        let bodyStart = terminatorRange.upperBound
        let availableBody = buffer.count - bodyStart

        let bodyLength: Int
        if let raw = headers["content-length"] {
            guard let declared = Int(raw), declared >= 0 else {
                throw ParseError.invalidContentLength
            }
            guard declared <= Self.maxBodyBytes else {
                throw ParseError.bodyExceedsMaxSize
            }
            bodyLength = declared
        } else {
            bodyLength = availableBody
        }

        if availableBody < bodyLength {
            return .needMoreData
        }

        let body = buffer.subdata(in: bodyStart ..< (bodyStart + bodyLength))
        let consumed = bodyStart + bodyLength
        let request = ParsedRequest(method: method, path: path, headers: headers, body: body)
        return .complete(request, consumed: consumed)
    }
}
