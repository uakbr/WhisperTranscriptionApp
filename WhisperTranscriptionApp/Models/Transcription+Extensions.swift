import Foundation

extension Transcription {
    func dateFormattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self.date ?? Date())
    }
} 