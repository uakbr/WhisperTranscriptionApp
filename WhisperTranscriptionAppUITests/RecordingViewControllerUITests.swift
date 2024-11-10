import XCTest

class RecordingViewControllerUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testRecordingFlow() {
        // Verify that the Start Recording button exists
        let startRecordingButton = app.buttons["Start Recording"]
        XCTAssertTrue(startRecordingButton.exists)
        
        // Tap Start Recording and check UI updates
        startRecordingButton.tap()
        
        // Verify that Pause and Stop buttons are visible
        let pauseButton = app.buttons["Pause Recording"]
        let stopButton = app.buttons["Stop Recording"]
        XCTAssertTrue(pauseButton.exists)
        XCTAssertTrue(stopButton.exists)
        
        // Verify that the transcription label updates (requires accessibility identifiers)
        let transcriptionLabel = app.staticTexts["transcriptionLabel"]
        XCTAssertTrue(transcriptionLabel.exists)
        
        // Wait for some time to simulate recording
        sleep(3)
        
        // Tap Stop Recording
        stopButton.tap()
        
        // Verify that recording stops and UI resets
        XCTAssertTrue(startRecordingButton.exists)
        XCTAssertFalse(pauseButton.exists)
        XCTAssertFalse(stopButton.exists)
    }
} 