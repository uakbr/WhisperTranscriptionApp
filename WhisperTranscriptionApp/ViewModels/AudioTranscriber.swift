import Foundation
import AVFoundation
import Accelerate

class AudioTranscriber: NSObject {
    // MARK: - Properties
    static let shared = AudioTranscriber()
    
    private let whisperManager = WhisperModelManager.shared
    private let tokenizer = WhisperTokenizer.shared
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode
    private var audioConverter: AVAudioConverter?
    
    // Audio format constants
    private let modelSampleRate: Double = 16000
    private let bufferSize: AVAudioFrameCount = 4096
    private let maxBufferCount = 1875 // 30 seconds at 16kHz
    private let processingInterval: TimeInterval = 0.5 // Process every 500ms
    
    // Transcription state
    private var isTranscribing = false
    private var transcriptionBuffer: [Float] = []
    private var currentTranscription: String = ""
    private var lastProcessedTime: TimeInterval = 0
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // Thread safety
    private let processingQueue = DispatchQueue(label: "com.whispertranscription.processing",
                                              qos: .userInitiated)
    private let transcriptionLock = NSLock()
    
    // Completion handlers
    private var transcriptionUpdateHandler: ((String) -> Void)?
    private var errorHandler: ((Error) -> Void)?
    
    private let bufferQueue = DispatchQueue(label: "com.whispertranscription.bufferQueue", qos: .userInitiated)
    private let processingSemaphore = DispatchSemaphore(value: 1)
    
    // MARK: - Initialization
    private override init() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        super.init()
        setupAudioSession()
        setupNotifications()
    }
    
    deinit {
        removeNotifications()
        stopTranscribing()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetooth])
            try session.setActive(true)
        } catch {
            errorHandler?(TranscriptionError.audioSessionSetupFailed(error))
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleInterruption),
                                             name: AVAudioSession.interruptionNotification,
                                             object: nil)
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleRouteChange),
                                             name: AVAudioSession.routeChangeNotification,
                                             object: nil)
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAudioConverter() throws {
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                       sampleRate: modelSampleRate,
                                       channels: 1,
                                       interleaved: false)!
        
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw TranscriptionError.audioConverterInitFailed
        }
        audioConverter = converter
    }
    
    // MARK: - Transcription Control
    func startTranscribing(updateHandler: @escaping (String) -> Void,
                          errorHandler: @escaping (Error) -> Void) throws {
        guard !isTranscribing else { return }
        
        self.transcriptionUpdateHandler = updateHandler
        self.errorHandler = errorHandler
        
        try setupAudioConverter()
        startBackgroundTask()
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                       sampleRate: modelSampleRate,
                                       channels: 1,
                                       interleaved: false)!
        
        inputNode.installTap(onBus: 0,
                           bufferSize: bufferSize,
                           format: inputNode.outputFormat(forBus: 0)) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, time: time)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isTranscribing = true
    }
    
    func stopTranscribing() {
        guard isTranscribing else { return }
        
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        // Process remaining audio in buffer
        processingQueue.async { [weak self] in
            self?.processRemainingAudio()
            self?.cleanupTranscription()
            
            // Ensure background task ends after processing
            DispatchQueue.main.async {
                self?.endBackgroundTask()
            }
        }
        
        isTranscribing = false
    }
    
    // MARK: - Background Task Management
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // MARK: - Audio Processing
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        bufferQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Wait if processing is ongoing
            self.processingSemaphore.wait()
            
            // Convert buffer to required format and process
            do {
                try self.processBuffer(buffer)
            } catch {
                self.handleError(error)
            }
            
            self.processingSemaphore.signal()
        }
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) throws {
        // Audio conversion and processing logic
        // Ensure minimal memory allocation and reuse buffers where possible
    }
    
    private func convertBuffer(_ buffer: AVAudioPCMBuffer) throws -> [Float] {
        guard let converter = audioConverter else {
            throw TranscriptionError.audioConverterNotInitialized
        }
        
        let frameCount = AVAudioFrameCount(modelSampleRate * processingInterval)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat,
                                                   frameCapacity: frameCount) else {
            throw TranscriptionError.bufferCreationFailed
        }
        
        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if let error = error {
            throw TranscriptionError.audioConversionFailed(error)
        }
        
        guard let channelData = convertedBuffer.floatChannelData?[0] else {
            throw TranscriptionError.invalidAudioData
        }
        
        return Array(UnsafeBufferPointer(start: channelData,
                                       count: Int(convertedBuffer.frameLength)))
    }
    
    private func appendToTranscriptionBuffer(_ newSamples: [Float]) {
        transcriptionLock.lock()
        defer { transcriptionLock.unlock() }
        
        transcriptionBuffer.append(contentsOf: newSamples)
        
        // Maintain buffer size limit
        if transcriptionBuffer.count > Int(modelSampleRate * maxAudioLength) {
            transcriptionBuffer.removeFirst(transcriptionBuffer.count - Int(modelSampleRate * maxAudioLength))
        }
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
        } catch {
            handleError(error)
        }
        
        transcriptionBuffer.removeAll()
    }
    
    // MARK: - Transcription Processing
    private func transcribeAudioChunk(_ chunk: [Float]) throws -> String {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                 sampleRate: modelSampleRate,
                                 channels: 1,
                                 interleaved: false)!
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                    frameCapacity: AVAudioFrameCount(chunk.count))!
        
        let channelData = buffer.floatChannelData![0]
        chunk.withUnsafeBufferPointer { ptr in
            channelData.initialize(from: ptr.baseAddress!, count: chunk.count)
        }
        buffer.frameLength = AVAudioFrameCount(chunk.count)
        
        return try whisperManager.transcribe(audioBuffer: buffer)
    }
    
    private func updateTranscription(_ newText: String) {
        currentTranscription += newText + " "
        DispatchQueue.main.async { [weak self] in
            self?.transcriptionUpdateHandler?(self?.currentTranscription ?? "")
        }
    }
    
    private func cleanupTranscription() {
        currentTranscription = ""
        transcriptionBuffer.removeAll()
        lastProcessedTime = 0
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
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                try? startTranscribing(
                    updateHandler: transcriptionUpdateHandler ?? { _ in },
                    errorHandler: errorHandler ?? { _ in }
                )
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            stopTranscribing()
        default:
            break
        }
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
}

// MARK: - Helper Extensions
extension AudioTranscriber {
    func clearTranscription() {
        transcriptionLock.lock()
        defer { transcriptionLock.unlock() }
        
        cleanupTranscription()
        transcriptionUpdateHandler?("")
    }
    
    var isActive: Bool {
        return isTranscribing
    }
}