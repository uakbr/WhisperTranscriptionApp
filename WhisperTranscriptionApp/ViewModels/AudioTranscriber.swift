import Foundation
import AVFoundation
import Accelerate

class AudioTranscriber: NSObject {
    // MARK: - Properties
    static let shared = AudioTranscriber()
    
    private let whisperManager = WhisperModelManager.shared
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode
    private var audioConverter: AVAudioConverter?
    
    // Audio format constants
    private let modelSampleRate: Double = 16000
    private let bufferSize: AVAudioFrameCount = 4096
    private let maxBufferCount = 1875 // 30 seconds at 16kHz
    
    // Transcription state
    private var isTranscribing = false
    private var transcriptionBuffer: [Float] = []
    private var currentTranscription: String = ""
    
    // Completion handlers
    private var transcriptionUpdateHandler: ((String) -> Void)?
    private var errorHandler: ((Error) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true)
        } catch {
            errorHandler?(TranscriptionError.audioSessionSetupFailed(error))
        }
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
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                       sampleRate: modelSampleRate,
                                       channels: 1,
                                       interleaved: false)!
        
        inputNode.installTap(onBus: 0,
                           bufferSize: bufferSize,
                           format: inputNode.outputFormat(forBus: 0)) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isTranscribing = true
    }
    
    func stopTranscribing() {
        guard isTranscribing else { return }
        
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        transcriptionBuffer.removeAll()
        isTranscribing = false
        
        // Process any remaining audio
        processRemainingAudio()
    }
    
    // MARK: - Audio Processing
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let converter = audioConverter else {
            errorHandler?(TranscriptionError.audioConverterNotInitialized)
            return
        }
        
        let frameCount = AVAudioFrameCount(modelSampleRate * 0.1) // 100ms chunks
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat,
                                                   frameCapacity: frameCount) else {
            errorHandler?(TranscriptionError.bufferCreationFailed)
            return
        }
        
        var error: NSError?
        converter.convert(to: convertedBuffer,
                        error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if let error = error {
            errorHandler?(TranscriptionError.audioConversionFailed(error))
            return
        }
        
        guard let channelData = convertedBuffer.floatChannelData?[0] else {
            errorHandler?(TranscriptionError.invalidAudioData)
            return
        }
        
        // Append converted audio data to buffer
        let newSamples = Array(UnsafeBufferPointer(start: channelData,
                                                  count: Int(convertedBuffer.frameLength)))
        transcriptionBuffer.append(contentsOf: newSamples)
        
        // Process transcription when we have enough data
        if transcriptionBuffer.count >= Int(modelSampleRate * 0.5) { // Process every 500ms
            processTranscriptionChunk()
        }
    }
    
    private func processTranscriptionChunk() {
        let chunkSize = Int(modelSampleRate * 0.5)
        guard transcriptionBuffer.count >= chunkSize else { return }
        
        let chunk = Array(transcriptionBuffer.prefix(chunkSize))
        transcriptionBuffer.removeFirst(chunkSize)
        
        do {
            let transcription = try transcribeAudioChunk(chunk)
            if !transcription.isEmpty {
                currentTranscription += transcription + " "
                transcriptionUpdateHandler?(currentTranscription)
            }
        } catch {
            errorHandler?(error)
        }
    }
    
    private func processRemainingAudio() {
        guard !transcriptionBuffer.isEmpty else { return }
        
        do {
            let transcription = try transcribeAudioChunk(transcriptionBuffer)
            if !transcription.isEmpty {
                currentTranscription += transcription
                transcriptionUpdateHandler?(currentTranscription)
            }
        } catch {
            errorHandler?(error)
        }
        
        transcriptionBuffer.removeAll()
    }
    
    // MARK: - Transcription
    private func transcribeAudioChunk(_ chunk: [Float]) throws -> String {
        // Create audio buffer for the chunk
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
        
        // Process through WhisperModelManager
        return try whisperManager.transcribe(audioBuffer: buffer)
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
}

// MARK: - Helper Extensions
extension AudioTranscriber {
    func clearTranscription() {
        currentTranscription = ""
        transcriptionUpdateHandler?("")
    }
    
    var isActive: Bool {
        return isTranscribing
    }
}