import AVFoundation

class AudioRecorder: NSObject {
    // MARK: - Properties
    static let shared = AudioRecorder()
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var isRecording = false
    
    // MARK: - Notifications
    static let recordingDidStart = Notification.Name("recordingDidStart")
    static let recordingDidPause = Notification.Name("recordingDidPause")
    static let recordingDidResume = Notification.Name("recordingDidResume")
    static let recordingDidStop = Notification.Name("recordingDidStop")
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Recording Controls
    func startRecording(to fileURL: URL) throws {
        guard !isRecording else { return }
        
        // Request microphone permission
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .undetermined:
            audioSession.requestRecordPermission { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        try? self?.startRecording(to: fileURL)
                    }
                } else {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .recordingDidStop, object: nil)
                    }
                }
            }
            return
        case .denied:
            throw AudioRecorderError.microphonePermissionDenied
        case .granted:
            break
        @unknown default:
            throw AudioRecorderError.microphonePermissionDenied
        }
        
        // Configure audio session
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        
        // Set up audio engine and file
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        audioFile = try AVAudioFile(forWriting: fileURL, settings: recordingFormat.settings)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            do {
                try self?.audioFile?.write(from: buffer)
            } catch {
                print("Error writing audio buffer: \(error)")
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        NotificationCenter.default.post(name: .recordingDidStart, object: nil)
    }
    
    func pauseRecording() {
        guard isRecording else { return }
        audioEngine?.pause()
        NotificationCenter.default.post(name: .recordingDidPause, object: nil)
    }
    
    func resumeRecording() throws {
        guard let audioEngine = audioEngine, !audioEngine.isRunning else { return }
        try audioEngine.start()
        NotificationCenter.default.post(name: .recordingDidResume, object: nil)
    }
    
    func stopRecording() {
        guard isRecording else { return }
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioFile = nil
        isRecording = false
        NotificationCenter.default.post(name: .recordingDidStop, object: nil)
    }
}

// MARK: - AudioRecorderError
enum AudioRecorderError: Error {
    case microphonePermissionDenied
}