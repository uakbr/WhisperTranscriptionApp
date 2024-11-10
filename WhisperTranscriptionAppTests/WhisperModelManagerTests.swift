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
        XCTAssertNoThrow(modelManager.loadModel(), "Model should load without throwing an error")
        XCTAssertNotNil(modelManager.model, "Model should not be nil after loading")
    }

    func testTranscription() {
        // Prepare a sample audio buffer with known content
        // For the purpose of this test, we'll use a prerecorded sample or mock data
        let sampleAudioBuffer = ... // Load or generate test audio buffer
        let expectation = self.expectation(description: "Transcription completes")

        modelManager.transcribe(audioBuffer: sampleAudioBuffer) { result in
            switch result {
            case .success(let transcription):
                XCTAssertFalse(transcription.isEmpty, "Transcription should not be empty")
                XCTAssertEqual(transcription, "Expected transcription text", "Transcription should match expected text")
            case .failure(let error):
                XCTFail("Transcription failed with error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
} 