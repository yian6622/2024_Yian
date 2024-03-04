import SwiftUI
import AVFoundation

// Represents a single piano key
struct PianoKey: View {
    let note: UInt8
    let label: String
    var isWhite: Bool = true
    var action: (UInt8, Bool) -> Void  // Updated to include a Bool to indicate start or stop
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isWhite ? Color.white : Color.black)
            Text(label)
                .foregroundColor(isWhite ? .black : .white)
        }
        .frame(width: isWhite ? 40 : 28, height: isWhite ? 200 : 120)
        .cornerRadius(isWhite ? 0 : 5)
        .shadow(radius: isWhite ? 0 : 2)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in action(note, true) })  // Start playing note
                .onEnded({ _ in action(note, false) })  // Stop playing note
        )
    }
}

struct PianoView: View {
    @State private var scale: [(UInt8, String)] = []
    @State private var audioEngine = AVAudioEngine()
    @State private var midiSampler = AVAudioUnitSampler()
    
    // Define scales with labels for keys
    let cMajorScale: [(UInt8, String)] = [
        (60, "C"), (62, "D"), (64, "E"), (65, "F"), (67, "G"), (69, "A"), (71, "B"),
        (72, "C"), (74, "D"), (76, "E"), (77, "F"), (79, "G"), (81, "A"), (83, "B")
    ]
    let cMinorScale: [(UInt8, String)] = [
        (60, "C"), (62, "D"), (63, "Eb"), (65, "F"), (67, "G"), (68, "Ab"), (70, "Bb"),
        (72, "C"), (74, "D"), (75, "Eb"), (77, "F"), (79, "G"), (80, "Ab"), (82, "Bb")
    ]
    
    init() {
        _scale = State(initialValue: cMajorScale)
        setupAudioEngine()
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(scale, id: \.0) { (note, label) in
                        PianoKey(note: note, label: label, isWhite: true) { note, shouldStart in
                            if shouldStart {
                                playMIDINote(note)
                            } else {
                                stopMIDINote(note)
                            }
                        }
                        .frame(width: 40, height: 200)
                    }
                }
            }
            .onAppear {
                setupAudioEngine()
            }

            Button("Switch to C Minor") {
                scale = cMinorScale
            }
            .padding()

            Button("Switch to C Major") {
                scale = cMajorScale
            }
            .padding()
        }
    }
    
    private func setupAudioEngine() {
        let _ = try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        let _ = try? AVAudioSession.sharedInstance().setActive(true)
        
        audioEngine.attach(midiSampler)
        audioEngine.connect(midiSampler, to: audioEngine.outputNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine couldn't start: \(error).")
        }
    }
    
    func playMIDINote(_ note: UInt8) {
        midiSampler.startNote(note, withVelocity: 64, onChannel: 0)
    }

    func stopMIDINote(_ note: UInt8) {
        midiSampler.stopNote(note, onChannel: 0)
    }

}
