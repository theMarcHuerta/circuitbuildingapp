import SwiftUI

struct GridView: View {
    let rows = 20
    let columns = 20

    var body: some View {
        GeometryReader { geometry in
            let gridSize = min(geometry.size.width / CGFloat(columns), geometry.size.height / CGFloat(rows))
            Path { path in
                for row in 0..<rows {
                    for column in 0..<columns {
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