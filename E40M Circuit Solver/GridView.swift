import SwiftUI

struct GridView: View {
    static let rows = 100
    static let columns = 150

    var body: some View {
        GeometryReader { geometry in
            let gridSize = min(geometry.size.width / CGFloat(Self.columns), geometry.size.height / CGFloat(Self.rows))
            Path { path in
                for row in 0..<Self.rows {
                    for column in 0..<Self.columns {
                        let x = CGFloat(column) * gridSize
                        let y = CGFloat(row) * gridSize
                        path.addRect(CGRect(x: x, y: y, width: gridSize, height: gridSize))
                    }
                }
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
        }
    }
}