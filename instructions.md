# Detailed Development Phases for WhisperTranscriptionApp

This document provides step-by-step guidance for each phase of the app development process, focusing on detailed implementation steps for an AI IDE tool to facilitate each component.

## Phase 1: Core Structure and Initial Setup
1. **App Delegate (AppDelegate.swift)**:
   - Create `AppDelegate.swift` and set up the main lifecycle method: `application(_:didFinishLaunchingWithOptions:)`.
   - Configure `AVAudioSession` in `didFinishLaunchingWithOptions` with the `playAndRecord` mode and set it as active, allowing audio to be captured during background recording.
   - Set `UIApplication.shared.isIdleTimerDisabled = true` to prevent the device from sleeping during recording.
2. **Scene Delegate (SceneDelegate.swift)**:
   - Initialize `SceneDelegate.swift` and implement `sceneWillEnterForeground(_:)` and `sceneDidEnterBackground(_:)` methods.
   - Use `sceneDidEnterBackground(_:)` to start a background task via `beginBackgroundTask(expirationHandler:)` to ensure the app continues running while minimized.

## Phase 2: Building the Audio Recorder
1. **AudioRecorder Class (AudioRecorder.swift)**:
   - Import `AVFoundation`, and in the `AudioRecorder` class, create an instance of `AVAudioRecorder`.
   - Add a function `prepareRecorder()` to configure the audio session settings with properties like `sampleRate`, `numberOfChannels`, and `audioQuality` using `AVAudioRecorderSettings`.
   - Define methods: `startRecording()`, `stopRecording()`, and `pauseRecording()`, which will manage recording actions by starting and stopping `AVAudioRecorder`.
2. **Handling Background Recording**:
   - Configure the audio session for background audio recording using `AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .allowBluetooth)`.
   - Implement error handling within each method to alert users if microphone access is restricted.

## Phase 3: Converting and Integrating the Whisper Model
1. **Model Conversion**:
   - Using Python, run `convert_whisper_to_coreml.py` to convert the Whisper model to CoreML format, specifying input shape and output format options for CoreML compatibility.
   - Place the converted model (`WhisperModel.mlmodel`) in the `Models` folder in Xcode.
2. **WhisperModelManager (WhisperModelManager.swift)**:
   - Create `WhisperModelManager` as a singleton with a function `loadModel()` to initialize and load `WhisperModel.mlmodel`.
   - Implement a function `predict(input:)` to accept preprocessed audio data and run inference. Use `MLMultiArray` for handling input data and extracting text from the model’s output.

## Phase 4: Developing the Audio Transcription Logic
1. **AudioTranscriber (AudioTranscriber.swift)**:
   - Define `transcribe(audioFile:)`, which takes the recorded audio file and sends it for preprocessing, ensuring it meets the model’s sample rate and format requirements.
   - Implement `preprocessAudio()` to down-sample or convert audio to match the model’s input specifications. Use `AVAudioConverter` for re-sampling.
   - Create `transcribeInRealTime()` that listens to audio buffers and feeds chunks to `WhisperModelManager` for real-time transcription.
2. **Text Output Handling**:
   - For each transcription chunk, update the UI with `transcription.appendedString`. Store transcription progress and handle punctuation insertion.

## Phase 5: Building the Recording Interface (RecordingViewController.swift)
1. **Recording Controls**:
   - Set up a `UILabel` to show real-time transcription text and a timer `UILabel` to track recording duration.
   - Add a `UIButton` to start recording, linked to `startRecording()` in `AudioRecorder`, and another button for pausing and stopping the recording.
2. **Transcription Display**:
   - Update `transcriptionLabel` every time `transcribeInRealTime()` processes a new chunk.
   - Format `transcriptionLabel` text for clarity and consistency, adjusting font size and line spacing dynamically.

## Phase 6: Transcription Management and Storage
1. **TranscriptionStorageManager (TranscriptionStorageManager.swift)**:
   - Use CoreData to save transcriptions with metadata (date, audio duration, etc.). Define `saveTranscription()`, `fetchTranscriptions()`, and `deleteTranscription()` methods.
   - Implement `fetchTranscriptions()` to retrieve saved transcription entries, ordered by the date or recording duration.
2. **Editable Transcriptions**:
   - In `TranscriptionViewController`, create `UITextView` to allow users to edit saved transcriptions.
   - Implement a “Save” button that updates the transcription in CoreData.

## Phase 7: Displaying Background Status on Dynamic Island
1. **RecordingLiveActivity (RecordingLiveActivity.swift)**:
   - Use `ActivityKit` to create a `LiveActivity` with fields for recording time and transcription progress.
   - Define a function `startLiveActivity()` in `RecordingLiveActivity` to initiate the Live Activity when recording starts.
   - Update the Live Activity with elapsed recording time and transcription status by using `Activity.contentState`.
2. **Dynamic Island Updates**:
   - In `DynamicIslandController.swift`, use `updateLiveActivityStatus()` to provide real-time updates to Dynamic Island, adjusting `recordingDuration` and showing active transcription progress.

## Phase 8: Implementing the Transcription Management UI
1. **TranscriptionViewController (TranscriptionViewController.swift)**:
   - Set up a `UITableView` to display saved transcriptions in rows, each showing metadata (date, time).
   - Add swipe actions for “Edit” and “Delete” on each row. Use `editTranscription(at:)` to allow text editing.
2. **Audio File Management**:
   - Provide playback options for saved audio. Implement `playAudioFile(at:)` in `AudioFileStorage.swift` to play audio.
   - Allow file deletion with an alert confirmation and corresponding removal from `CoreData`.

## Phase 9: Error Handling and Notifications
1. **ErrorAlertManager (ErrorAlertManager.swift)**:
   - Centralize error handling with `showAlert(title:message:)` that displays user-friendly error messages.
   - Implement specific alerts for microphone permission denial, CoreML model loading issues, and storage errors.
2. **Error Handling Integration**:
   - In `RecordingViewController`, wrap start and stop recording calls in `do-catch` blocks, using `ErrorAlertManager` to catch errors.
   - Similarly, handle CoreData errors in `TranscriptionStorageManager` to alert users when saving or deleting fails.

## Phase 10: Final Testing and Optimization
1. **Testing and Validation**:
   - Create unit tests in `WhisperTranscriptionAppTests` to validate transcription accuracy, model loading, and error handling. Use `XCTest` for testing individual components.
   - Add UI tests in `WhisperTranscriptionAppUITests` to verify button functionality, UI layout, and Dynamic Island updates.
2. **Performance Optimization**:
   - Profile `WhisperModelManager` and `AudioTranscriber` to ensure efficient memory usage and real-time processing.
   - Adjust CoreData fetch requests for optimal storage retrieval, ensuring smooth performance even with multiple saved transcriptions.
3. **Final UI Adjustments**:
   - Fine-tune UI alignment and spacing for Dynamic Island content, recording controls, and transcription display.
   - Ensure consistent font and color use for a cohesive visual experience.
