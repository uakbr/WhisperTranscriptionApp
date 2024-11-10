import Foundation
import NaturalLanguage

class WhisperTokenizer {
    static let shared = WhisperTokenizer()
    private var tokenToIndexMap: [String: Int] = [:]
    private let tokenizer = NLTokenizer(unit: .word)
    private let synchronizationQueue = DispatchQueue(label: "com.whispertranscription.tokenizerQueue")

    private init() {
        loadTokens()
    }

    private func loadTokens() {
        // Load tokens from whisper_tokens.json
        // ...
    }

    func encode(_ text: String) throws -> [Int] {
        return try synchronizationQueue.sync {
            tokenizer.string = text
            var tokens: [String] = []
            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
                let token = String(text[tokenRange])
                tokens.append(token)
                return true
            }

            return try tokens.map { token in
                try tokenToIndex(token)
            }
        }
    }

    private func tokenToIndex(_ token: String) throws -> Int {
        if let index = tokenToIndexMap[token] {
            return index
        } else {
            throw TokenizationError.tokenNotFound(token)
        }
    }
} 