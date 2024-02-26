import SwiftUI
import AVFoundation

struct TrackDetailView: View {
    var trackName: String // Example: "Track1"
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0

    var body: some View {
        VStack {
            // Adjusted to load from a folder reference
            if let img = UIImage(named: "Image/\(trackName)") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
            } else {
                Text("Image not found")
            }

            Slider(value: $playbackProgress, in: 0...1, step: 0.01)
                .padding()
                .accentColor(.pink)

            Button(action: {
                self.togglePlayPause()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.pink)
            }
        }
        .background(Color.black)
        .navigationBarTitle(trackName, displayMode: .inline)
        .onAppear {
            self.setupAudioPlayer()
        }
    }

    private func setupAudioPlayer() {
        guard let url = Bundle.main.url(forResource: trackName, withExtension: "m4a", subdirectory: "Audio") else {
            print("Audio file not found for \(trackName). Check if it's added to the project as a bundle resource.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error loading \(trackName).m4a: \(error)")
        }
    }


    private func togglePlayPause() {
        guard let player = audioPlayer else { return }

        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
            // Implement the playback progress tracking logic here
        }
    }
}
