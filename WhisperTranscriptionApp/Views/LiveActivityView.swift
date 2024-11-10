import SwiftUI
import ActivityKit

struct LiveActivityView: View {
    let context: ActivityViewContext<RecordingAttributes>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.red)
                Text("Recording...")
                    .font(.headline)
            }
            Text(formattedElapsedTime)
                .font(.subheadline)
                .padding(.top, 2)
            Text(context.state.transcriptionProgress)
                .font(.caption)
                .lineLimit(1)
                .padding(.top, 2)
        }
        .padding()
    }
    
    private var formattedElapsedTime: String {
        let totalSeconds = Int(context.state.elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d elapsed", minutes, seconds)
    }
}

@available(iOSApplicationExtension 16.1, *)
struct LiveActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let attributes = RecordingAttributes(sessionName: "Preview Session")
        let contentState = RecordingAttributes.ContentState(
            elapsedTime: 65,
            transcriptionProgress: "Hello, world!"
        )
        LiveActivityView(context: .init(attributes: attributes, state: contentState))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}