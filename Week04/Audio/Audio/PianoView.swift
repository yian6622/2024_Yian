import SwiftUI

struct PianoView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(0..<12) { key in // Example for 12 keys
                    Button(action: {
                        // Action to play sound
                    }) {
                        Rectangle()
                            .fill(key % 2 == 0 ? Color.white : Color.gray) // Alternating colors for keys
                            .frame(width: 60, height: 200)
                    }
                }
            }
        }
        .background(Color.black)
        .navigationBarTitle("Piano", displayMode: .inline)
    }
}
