import SwiftUI

struct GridView: View {
    static let gridSize: CGFloat = 14
    static let rows = 100
    static let columns = 150

    var body: some View {
        Path { path in
            for row in 0..<Self.rows {
                for column in 0..<Self.columns {
                    let x = CGFloat(column) * Self.gridSize
                    let y = CGFloat(row) * Self.gridSize
                    path.addRect(CGRect(x: x, y: y, width: Self.gridSize, height: Self.gridSize))
                }
            }
        }
        .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
    }
}