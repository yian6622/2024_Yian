import SwiftUI
import AVFoundation

struct MIDINoteEvent: Codable {
    let note: UInt8
    let isOn: Bool
    let timestamp: TimeInterval
}

class MIDIRecorder {
    private var events: [MIDINoteEvent] = []
    private var startTime: Date?
    
    func startRecording() {
        startTime = Date()
        events.removeAll()
    }
    
    func recordEvent(note: UInt8, isOn: Bool) {
        guard let startTime = startTime else { return }
        let currentTime = Date()
        let event = MIDINoteEvent(note: note, isOn: isOn, timestamp: currentTime.timeIntervalSince(startTime))
        events.append(event)
    }
    
    func stopRecording() -> [MIDINoteEvent] {
        return events
    }
    
    func saveRecording(to url: URL) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(events)
            try data.write(to: url)
        } catch {
            print("Failed to save recording: \(error)")
        }
    }
    
    func loadRecording(from url: URL) -> [MIDINoteEvent]? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let events = try decoder.decode([MIDINoteEvent].self, from: data)
            return events
        } catch {
            print("Failed to load recording: \(error)")
            return nil
        }
    }
}

struct PianoKey: View {
    let note: UInt8
    let label: String
    var isWhite: Bool = true
    var action: (UInt8, Bool) -> Void // Updated to include a Boolean for press/release
    
    @State private var isPressed = false // Track whether the key is pressed

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isPressed ? Color.gray : (isWhite ? Color.white : Color.black)) // Change color on press
                .cornerRadius(isWhite ? 0 : 5)
                .shadow(radius: isWhite ? 0 : 2)
            
            Text(label)
                .foregroundColor(isWhite ? .black : .white)
                .font(.caption)
        }
        .frame(width: isWhite ? 40 : 28, height: isWhite ? 200 : 120) // Adjusted size for white and black keys
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in
                    self.isPressed = true
                    self.action(note, true) // Start playing the note
                })
                .onEnded({ _ in
                    self.isPressed = false
                    self.action(note, false) // Stop playing the note
                })
        )
    }
}

struct PianoView: View {
    @State private var scale: [(UInt8, String)] = []
    @State private var audioEngine = AVAudioEngine()
    @State private var midiSampler = AVAudioUnitSampler()
    @State private var recorder = MIDIRecorder()

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
                        PianoKey(note: note, label: label, isWhite: true) { note, isPressed in
                            if isPressed {
                                playMIDINote(note)
                            } else {
                                stopMIDINote(note)
                            }
                        }
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

            Button("Start Recording") {
                recorder.startRecording()
            }
            .padding()

            Button("Stop and Save Recording") {
                _ = recorder.stopRecording()
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent("MIDIRecording.json")
                recorder.saveRecording(to: fileURL)
            }
            .padding()
            
            Button("Play Recording") {
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent("MIDIRecording.json")
                if let events = recorder.loadRecording(from: fileURL) {
                    playEvents(events)
                }
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
        recorder.recordEvent(note: note, isOn: true)
    }

    func stopMIDINote(_ note: UInt8) {
        midiSampler.stopNote(note, onChannel: 0)
        recorder.recordEvent(note: note, isOn: false)
    }

    func playEvents(_ events: [MIDINoteEvent]) {
        for event in events {
            let delay = event.timestamp
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if event.isOn {
                    self.playMIDINote(event.note)
                } else {
                    self.stopMIDINote(event.note)
                }
            }
        }
    }
}
