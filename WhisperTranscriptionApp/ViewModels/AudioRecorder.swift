import AVFoundation

class AudioRecorder: NSObject {
    // MARK: - Properties
    static let shared = AudioRecorder()
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?
    
    // Recording state
    private(set) var isRecording = false
    private(set) var isPaused = false
    
    // Current recording URL
    private(set) var currentRecordingURL: URL?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupRecordingSession()
    }
    
    // MARK: - Setup
    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            try recordingSession?.setActive(true)
        } catch {
            ErrorAlertManager.shared.showAlert(
                title: "Recording Setup Failed",
                message: "Failed to set up the recording session: \(error.localizedDescription)"
            )
        }
    }
    
    private func prepareRecorder() throws -> URL {
        // Create a unique file URL in the temporary directory
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Audio settings optimized for speech recognition
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create and configure the audio recorder
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        
        return audioFilename
    }
    
    // MARK: - Recording Controls
    func startRecording() throws {
        guard !isRecording else { return }
        
        // Check microphone permission
        guard let recordingSession = recordingSession else {
            throw AudioRecorderError.sessionNotInitialized
        }
        
        if recordingSession.recordPermission != .granted {
            throw AudioRecorderError.noMicrophonePermission
        }
        
        do {
            currentRecordingURL = try prepareRecorder()
            
            guard let audioRecorder = audioRecorder else {
                throw AudioRecorderError.recorderNotInitialized
            }
            
            audioRecorder.record()
            isRecording = true
            isPaused = false
            
            // Notify that recording has started
            NotificationCenter.default.post(name: .recordingDidStart, object: nil)
        } catch {
            throw AudioRecorderError.failedToStartRecording(error)
        }
    }
    
    func pauseRecording() {
        guard isRecording, !isPaused else { return }
        audioRecorder?.pause()
        isPaused = true
        
        // Notify that recording was paused
        NotificationCenter.default.post(name: .recordingDidPause, object: nil)
    }
    
    func resumeRecording() {
        guard isRecording, isPaused else { return }
        audioRecorder?.record()
        isPaused = false
        
        // Notify that recording was resumed
        NotificationCenter.default.post(name: .recordingDidResume, object: nil)
    }
    
    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        
        let finalURL = currentRecordingURL
        audioRecorder?.stop()
        isRecording = false
        isPaused = false
        
        // Notify that recording has stopped
        NotificationCenter.default.post(name: .recordingDidStop, object: finalURL)
        
        return finalURL
    }
    
    // MARK: - Audio Metering
    func getAudioPower() -> Float {
        guard let recorder = audioRecorder, isRecording else { return -160.0 }
        
        recorder.updateMeters()
        return recorder.averagePower(forChannel: 0)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            ErrorAlertManager.shared.showAlert(
                title: "Recording Failed",
                message: "The recording was unsuccessful. Please try again."
            )
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            ErrorAlertManager.shared.showAlert(
                title: "Recording Error",
                message: "An error occurred while recording: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Custom Errors
enum AudioRecorderError: Error {
    case sessionNotInitialized
    case noMicrophonePermission
    case recorderNotInitialized
    case failedToStartRecording(Error)
}

// MARK: - Notification Names
extension Notification.Name {
    static let recordingDidStart = Notification.Name("recordingDidStart")
    static let recordingDidPause = Notification.Name("recordingDidPause")
    static let recordingDidResume = Notification.Name("recordingDidResume")
    static let recordingDidStop = Notification.Name("recordingDidStop")
}