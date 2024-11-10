import XCTest
@testable import WhisperTranscriptionApp

class WhisperModelManagerTests: XCTestCase {
    var modelManager: WhisperModelManager!

    override func setUp() {
        super.setUp()
        modelManager = WhisperModelManager.shared
    }

    override func tearDown() {
        modelManager = nil
        super.tearDown()
    }

    func testModelLoading() {
        // Test that the model loads without throwing errors
        XCTAssertNoThrow(try modelManager.loadModel(), "Model should load without throwing an error")
        XCTAssertNotNil(modelManager.model, "Model should not be nil after loading")
    }

    func testTranscriptionWithValidAudio() {
        // Prepare a sample audio buffer with known content
        guard let bundle = Bundle(for: type(of: self)),
              let audioURL = bundle.url(forResource: "test_sample", withExtension: "wav"),
              let file = try? AVAudioFile(forReading: audioURL),
              let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: 16000.0,
                                         channels: 1,
                                         interleaved: false) else {
            XCTFail("Failed to load test audio file")
            return
        }

        let frameCount = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            XCTFail("Failed to create PCM buffer")
            return
        }

        do {
            try file.read(into: buffer)
            let expectation = self.expectation(description: "Transcription completes")

            modelManager.transcribe(audioBuffer: buffer) { result in
                switch result {
                case .success(let transcription):
                    XCTAssertFalse(transcription.isEmpty, "Transcription should not be empty")
                    XCTAssertEqual(transcription.lowercased(), "this is a test sample", "Transcription should match expected text")
                case .failure(let error):
                    XCTFail("Transcription failed with error: \(error)")
                }
                expectation.fulfill()
            }

            waitForExpectations(timeout: 10, handler: nil)
        } catch {
            XCTFail("Error reading test audio file: \(error)")
        }
    }

    func testTranscriptionWithInvalidAudio() {
        // Create an empty audio buffer to simulate invalid input
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000.0, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 0)!

        let expectation = self.expectation(description: "Transcription completes")

        modelManager.transcribe(audioBuffer: buffer) { result in
            switch result {
            case .success(_):
                XCTFail("Transcription should fail with invalid audio data")
            case .failure(let error):
                XCTAssertNotNil(error, "Error should not be nil")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
} 