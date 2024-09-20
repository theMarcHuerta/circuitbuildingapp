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
        self.leftTerminal = Terminal(componentID: id, position: CGPoint(x: position.x - 20, y: position.y))
        self.rightTerminal = Terminal(componentID: id, position: CGPoint(x: position.x + 20, y: position.y))
    }
}

struct Terminal: Identifiable {
    let id = UUID()
    let componentID: UUID
    var position: CGPoint
    var isSelected: Bool = false
}

struct Node: Hashable {
    let x, y: Int
    var f, g, h: Int
    var parent: (Int, Int)?

    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }

    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

struct Wire: Identifiable {
    let id = UUID()
    var startComponentID: UUID
    var endComponentID: UUID
    var startIsLeft: Bool
    var endIsLeft: Bool
    var path: [CGPoint]

    init(startComponentID: UUID, endComponentID: UUID, startIsLeft: Bool, endIsLeft: Bool, startPoint: CGPoint, endPoint: CGPoint, existingWires: [Wire], components: [Component]) {
        self.startComponentID = startComponentID
        self.endComponentID = endComponentID
        self.startIsLeft = startIsLeft
        self.endIsLeft = endIsLeft
        self.path = Wire.calculatePath(from: startPoint, to: endPoint, avoidingComponents: components)
    }

    static func calculatePath(from start: CGPoint, to end: CGPoint, avoidingComponents components: [Component]) -> [CGPoint] {
        let gridSize: CGFloat = 10
        let startSnapped = CGPoint(x: round(start.x / gridSize) * gridSize, y: round(start.y / gridSize) * gridSize)
        let endSnapped = CGPoint(x: round(end.x / gridSize) * gridSize, y: round(end.y / gridSize) * gridSize)

        var path = [startSnapped]

        let dx = endSnapped.x - startSnapped.x
        let dy = endSnapped.y - startSnapped.y

        if abs(dx) > abs(dy) {
            // Horizontal dominant
            let midX = startSnapped.x + dx / 2
            path.append(CGPoint(x: midX, y: startSnapped.y))
            path.append(CGPoint(x: midX, y: endSnapped.y))
        } else {
            // Vertical dominant
            let midY = startSnapped.y + dy / 2
            path.append(CGPoint(x: startSnapped.x, y: midY))
            path.append(CGPoint(x: endSnapped.x, y: midY))
        }

        path.append(endSnapped)

        return path
    }
}

struct SelectedTerminal: Equatable {
    let componentID: UUID
    let isLeftTerminal: Bool
}