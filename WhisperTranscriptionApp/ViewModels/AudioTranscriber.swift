import Foundation
import AVFoundation
import Accelerate

class AudioTranscriber: NSObject {
    // MARK: - Properties
    static let shared = AudioTranscriber()
    
    private let whisperManager = WhisperModelManager.shared
    private let tokenizer = WhisperTokenizer.shared
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioConverter: AVAudioConverter?
    
    private var transcriptionBuffer = [Float]()
    private let transcriptionLock = NSLock()
    private var isTranscribing = false
    private let modelSampleRate: Double = 16000.0
    private let processingInterval: TimeInterval = 5.0
    private let maxAudioLength: TimeInterval = 30.0
    
    private var transcriptionUpdateHandler: ((String) -> Void)?
    private var errorHandler: ((Error) -> Void)?
    private var currentTranscription = ""
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Initialization
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    // MARK: - Transcription Controls
    func startTranscribing(updateHandler: @escaping (String) -> Void, errorHandler: @escaping (Error) -> Void) throws {
        transcriptionLock.lock()
        defer { transcriptionLock.unlock() }
        
        guard !isTranscribing else { return }
        isTranscribing = true
        self.transcriptionUpdateHandler = updateHandler
        self.errorHandler = errorHandler
        
        try setupAudioEngine()
        startBackgroundTask()
    }
    
    func stopTranscribing() {
        transcriptionLock.lock()
        defer { transcriptionLock.unlock() }
        
        guard isTranscribing else { return }
        isTranscribing = false
        
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        audioConverter = nil
        
        processRemainingAudio()
        endBackgroundTask()
    }
    
    // MARK: - Audio Engine Setup
    private func setupAudioEngine() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        // Configure audio session
        try audioSession.setCategory(.record, mode: .default, options: [])
        try audioSession.setActive(true, options: [])
        
        // Check microphone permission
        switch audioSession.recordPermission {
        case .granted:
            break
        case .denied:
            throw TranscriptionError.microphonePermissionDenied
        case .undetermined:
            audioSession.requestRecordPermission { [weak self] granted in
                if !granted {
                    self?.handleError(TranscriptionError.microphonePermissionDenied)
                }
            }
            return
        @unknown default:
            throw TranscriptionError.microphonePermissionDenied
        }
        
        // Set up audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { throw TranscriptionError.audioSessionSetupFailed(NSError()) }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { throw TranscriptionError.audioSessionSetupFailed(NSError()) }
        
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let requiredFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: modelSampleRate, channels: 1, interleaved: false)
        
        guard let converter = AVAudioConverter(from: inputFormat, to: requiredFormat!) else {
            throw TranscriptionError.audioConverterInitFailed
        }
        audioConverter = converter
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        try audioEngine.start()
    }
    
    // MARK: - Audio Processing
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let audioConverter = audioConverter else {
            handleError(TranscriptionError.audioConverterNotInitialized)
            return
        }
        
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: modelSampleRate, channels: 1, interleaved: false)!, frameCapacity: AVAudioFrameCount(buffer.frameCapacity))
        
        do {
            try audioConverter.convert(to: convertedBuffer!, error: nil, withInputFrom: inputBlock)
        } catch {
            handleError(TranscriptionError.audioConversionFailed(error))
            return
        }
        
        guard let floatChannelData = convertedBuffer?.floatChannelData else {
            handleError(TranscriptionError.bufferCreationFailed)
            return
        }
        
        let channelData = Array(UnsafeBufferPointer(start: floatChannelData[0], count: Int(convertedBuffer!.frameLength)))
        
        transcriptionLock.lock()
        transcriptionBuffer.append(contentsOf: channelData)
        transcriptionLock.unlock()
        
        // Limit buffer size
        transcriptionLock.lock()
        if transcriptionBuffer.count > Int(modelSampleRate * maxAudioLength) {
            transcriptionBuffer.removeFirst(transcriptionBuffer.count - Int(modelSampleRate * maxAudioLength))
        }
        transcriptionLock.unlock()
        
        // Process transcription chunk
        try? processTranscriptionChunk()
    }
    
    private func processTranscriptionChunk() throws {
        transcriptionLock.lock()
        defer { transcriptionLock.unlock() }
        
        let chunkSize = Int(modelSampleRate * processingInterval)
        guard transcriptionBuffer.count >= chunkSize else { return }
        
        let chunk = Array(transcriptionBuffer.prefix(chunkSize))
        transcriptionBuffer.removeFirst(chunkSize)
        
        let transcription = try transcribeAudioChunk(chunk)
        if !transcription.isEmpty {
            updateTranscription(transcription)
        }
    }
    
    private func processRemainingAudio() {
        transcriptionLock.lock()
        defer { transcriptionLock.unlock() }
        
        guard !transcriptionBuffer.isEmpty else { return }
        
        do {
            let transcription = try transcribeAudioChunk(transcriptionBuffer)
            if !transcription.isEmpty {
                updateTranscription(transcription)
            }
            transcriptionBuffer.removeAll()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Transcription
    private func transcribeAudioChunk(_ audioData: [Float]) throws -> String {
        let inputBuffer = UnsafeMutablePointer<Float>.allocate(capacity: audioData.count)
        defer { inputBuffer.deallocate() }
        audioData.copyBytes(to: inputBuffer, count: audioData.count * MemoryLayout<Float>.size)
        
        guard let transcription = try? whisperManager.transcribe(audioBuffer: inputBuffer, bufferSize: audioData.count) else {
            throw TranscriptionError.transcriptionFailed(NSError())
        }
        
        return transcription
    }
    
    private func updateTranscription(_ newText: String) {
        DispatchQueue.main.async { [weak self] in
            self?.currentTranscription += newText + " "
            self?.transcriptionUpdateHandler?(self?.currentTranscription ?? "")
        }
    }
    
    // MARK: - Background Task Management
    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "TranscriptionBackgroundTask") { [weak self] in
            self?.stopTranscribing()
            self?.handleError(TranscriptionError.backgroundTaskExpired)
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    // MARK: - Cleanup
    private func cleanupTranscription() {
        currentTranscription = ""
        transcriptionBuffer.removeAll()
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorHandler?(error)
        }
    }
    
    // MARK: - Audio Session Handling
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            stopTranscribing()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    try? startTranscribing(
                        updateHandler: transcriptionUpdateHandler ?? { _ in },
                        errorHandler: errorHandler ?? { _ in }
                    )
                }
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - Public Methods
    func clearTranscription() {
        transcriptionLock.lock()
        defer { transcriptionLock.unlock() }
        
        cleanupTranscription()
        DispatchQueue.main.async { [weak self] in
            self?.transcriptionUpdateHandler?("")
        }
    }
    
    var isActive: Bool {
        transcriptionLock.lock()
        defer { transcriptionLock.unlock() }
        return isTranscribing
    }
}

// MARK: - Errors
enum TranscriptionError: Error {
    case audioSessionSetupFailed(Error)
    case audioConverterInitFailed
    case audioConverterNotInitialized
    case bufferCreationFailed
    case audioConversionFailed(Error)
    case invalidAudioData
    case transcriptionFailed(Error)
    case backgroundTaskExpired
    case microphonePermissionDenied
}