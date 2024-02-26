import SwiftUI
import AVFoundation

struct TrackDetailView: View {
    var trackName: String // Example: "Track1"
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var audioLength: Double = 1 // Initialize to ensure it's always positive

    var body: some View {
        VStack {
            // Adjusted for new "Files" folder structure
            if let img = UIImage(named: "Files/\(trackName)") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
            } else {
                Text("Image not found")
            }

            // Slider to control playback progress
            Slider(value: $playbackProgress, in: 0...max(audioLength, 1), step: 0.1, onEditingChanged: sliderEditingChanged)
                .padding()
                .accentColor(.pink)

            // Play/Pause Button
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
        // Adjusted for new "Files" folder structure
        guard let url = Bundle.main.url(forResource: "Files/\(trackName)", withExtension: "m4a") else {
            print("Audio file not found for \(trackName).")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioLength = audioPlayer?.duration ?? 1 // Update to audio duration or keep 1 if not available
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
            startTrackingPlaybackTime()
        }
    }

    private func startTrackingPlaybackTime() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let player = audioPlayer, player.isPlaying {
                playbackProgress = player.currentTime
            } else {
                timer.invalidate()
            }
        }
    }

    private func sliderEditingChanged(editingStarted: Bool) {
        if !editingStarted {
            audioPlayer?.currentTime = playbackProgress
            if isPlaying {
                audioPlayer?.play()
            }
        } else {
            audioPlayer?.pause()
        }
    }
}
