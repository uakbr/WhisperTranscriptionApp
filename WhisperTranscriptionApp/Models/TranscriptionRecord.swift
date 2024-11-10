import Foundation
import CloudKit

struct TranscriptionRecord {
    let recordID: CKRecord.ID
    let text: String
    let date: Date
    let duration: TimeInterval
    let audioURL: URL?

    init?(record: CKRecord) {
        guard let text = record["text"] as? String,
              let date = record["date"] as? Date,
              let duration = record["duration"] as? TimeInterval else { return nil }

        self.recordID = record.recordID
        self.text = text
        self.date = date
        self.duration = duration

        if let asset = record["audioAsset"] as? CKAsset, let fileURL = asset.fileURL {
            self.audioURL = fileURL
        } else {
            self.audioURL = nil
        }
    }

    // For creating new records to save
    init(text: String, date: Date, duration: TimeInterval, audioURL: URL?) {
        self.recordID = CKRecord.ID()
        self.text = text
        self.date = date
        self.duration = duration
        self.audioURL = audioURL
    }
} 