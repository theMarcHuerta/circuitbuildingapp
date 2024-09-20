import SwiftUI

struct WireView: View {
    let wire: Wire

    var body: some View {
        Path { path in
            guard let firstPoint = wire.path.first else { return }
            path.move(to: firstPoint)
            for point in wire.path.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(Color.black, lineWidth: 2)
    }
}
