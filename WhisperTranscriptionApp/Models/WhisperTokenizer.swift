import Foundation

class WhisperTokenizer {
    static let shared = WhisperTokenizer()
    
    private var tokenToIndex: [String: Int] = [:]
    private var indexToToken: [Int: String] = [:]
    
    private init() {
        loadTokenizer()
    }
    
    private func loadTokenizer() {
        guard let url = Bundle.main.url(forResource: "whisper_tokens", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tokens = try? JSONDecoder().decode([String: Int].self, from: data) else {
            fatalError("Failed to load tokenizer vocabulary")
        }
        
        tokenToIndex = tokens
        indexToToken = Dictionary(uniqueKeysWithValues: tokens.map { ($1, $0) })
    }
    
    func tokenToIndex(_ token: String) throws -> Int {
        guard let index = tokenToIndex[token] else {
            throw WhisperError.tokenizationError
        }
        return index
    }
    
    func indexToToken(_ index: Int) throws -> String {
        guard let token = indexToToken[index] else {
            throw WhisperError.tokenizationError
        }
        return token
    }
    
    func encode(_ text: String) throws -> [Int] {
        // Basic tokenization - in practice, you'd want more sophisticated rules
        let tokens = text.split(separator: " ").map(String.init)
        return try tokens.map { try tokenToIndex($0) }
    }
    
    func decode(_ indices: [Int]) throws -> String {
        try indices.map { try indexToToken($0) }.joined(separator: " ")
    }
} 