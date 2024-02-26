import SwiftUI

struct PianoView: View {
    // Indices for white keys in two octaves
    let whiteKeys = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23]
    // Indices for black keys in two octaves, -1 represents a gap
    let blackKeys = [1, 3, -1, 6, 8, 10, -1, 13, 15, -1, 18, 20, 22]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .leading) {
                HStack(spacing: 0) { // White keys
                    ForEach(whiteKeys, id: \.self) { key in
                        Button(action: {
                            playSound(for: key)
                        }) {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 40, height: 200)
                        }
                    }
                }
                HStack(spacing: 0) { // Black keys
                    ForEach(0..<blackKeys.count, id: \.self) { index in
                        if blackKeys[index] != -1 {
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 25, height: 120)
                                .offset(x: CGFloat(index) * 20 + 15, y: 0)
                                .onTapGesture {
                                    playSound(for: blackKeys[index])
                                }
                        }
                    }
                }
            }
        }
        .frame(height: 200)
        .background(Color.black)
        .navigationBarTitle("Piano", displayMode: .inline)
    }
    
    func playSound(for key: Int) {
        // Placeholder for playing sound
        print("Play sound for key: \(key)")
        // Here, you'd trigger the oscillator or sound playback
    }
}
