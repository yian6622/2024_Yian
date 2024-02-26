import SwiftUI

struct PlaylistView: View {
    var body: some View {
        List {
            NavigationLink("Track 1", destination: TrackDetailView(trackName: "Track1"))
            NavigationLink("Track 2", destination: TrackDetailView(trackName: "Track2"))
        }
    }
}
