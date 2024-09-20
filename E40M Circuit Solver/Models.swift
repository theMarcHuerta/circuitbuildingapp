import SwiftUI

struct Component: Identifiable {
    let id = UUID()
    let type: String
    var position: CGPoint
    var connections: [UUID] = []
    var leftTerminal: Terminal
    var rightTerminal: Terminal

    init(type: String, position: CGPoint) {
        self.type = type
        self.position = position
        self.leftTerminal = Terminal(componentID: id, position: CGPoint(x: position.x - GridView.gridSize * 2, y: position.y))
        self.rightTerminal = Terminal(componentID: id, position: CGPoint(x: position.x + GridView.gridSize * 2, y: position.y))
    }
}

struct Terminal: Identifiable {
    let id = UUID()
    let componentID: UUID
    var position: CGPoint
    var isSelected: Bool = false
}

struct Wire: Identifiable {
    let id = UUID()
    var startComponentID: UUID
    var endComponentID: UUID
    var startIsLeft: Bool
    var endIsLeft: Bool
    var path: [CGPoint]

    init(startComponentID: UUID, endComponentID: UUID, startIsLeft: Bool, endIsLeft: Bool, startPoint: CGPoint, endPoint: CGPoint, scale: CGFloat, offset: CGSize) {
        self.startComponentID = startComponentID
        self.endComponentID = endComponentID
        self.startIsLeft = startIsLeft
        self.endIsLeft = endIsLeft
        self.path = Wire.calculatePath(from: startPoint, to: endPoint, scale: scale, offset: offset)
    }

    static func calculatePath(from start: CGPoint, to end: CGPoint, scale: CGFloat, offset: CGSize) -> [CGPoint] {
        let gridSize = GridView.gridSize
        let startSnapped = snapToGrid(start)
        let endSnapped = snapToGrid(end)

        var path = [startSnapped]

        let dx = endSnapped.x - startSnapped.x
        let dy = endSnapped.y - startSnapped.y

        if abs(dx) > abs(dy) {
            path.append(CGPoint(x: endSnapped.x, y: startSnapped.y))
        } else {
            path.append(CGPoint(x: startSnapped.x, y: endSnapped.y))
        }

        path.append(endSnapped)

        return path.map { point in
            CGPoint(
                x: point.x * scale + offset.width,
                y: point.y * scale + offset.height
            )
        }
    }

    private static func snapToGrid(_ point: CGPoint) -> CGPoint {
        let gridSize = GridView.gridSize
        return CGPoint(
            x: round(point.x / gridSize) * gridSize,
            y: round(point.y / gridSize) * gridSize
        )
    }
}

struct SelectedTerminal: Equatable {
    let componentID: UUID
    let isLeftTerminal: Bool
}