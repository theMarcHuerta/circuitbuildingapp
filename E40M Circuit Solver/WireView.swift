import SwiftUI

struct WireView: View {
    let wire: Wire

    var body: some View {
        Path { path in
            path.move(to: wire.path.first!)
            for point in wire.path.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(Color.black, lineWidth: 2)
    }
}
