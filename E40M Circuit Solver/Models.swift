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
        self.leftTerminal = Terminal(componentID: id, position: CGPoint(x: position.x - 40, y: position.y))
        self.rightTerminal = Terminal(componentID: id, position: CGPoint(x: position.x + 40, y: position.y))
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

    init(startComponentID: UUID, endComponentID: UUID, startIsLeft: Bool, endIsLeft: Bool, startPoint: CGPoint, endPoint: CGPoint, existingWires: [Wire]) {
        self.startComponentID = startComponentID
        self.endComponentID = endComponentID
        self.startIsLeft = startIsLeft
        self.endIsLeft = endIsLeft
        self.path = Wire.calculatePath(from: startPoint, to: endPoint, avoidingWires: existingWires)
    }

    static func calculatePath(from start: CGPoint, to end: CGPoint, avoidingWires existingWires: [Wire]) -> [CGPoint] {
        let gridSize: CGFloat = 20
        let startSnapped = CGPoint(x: round(start.x / gridSize) * gridSize, y: round(start.y / gridSize) * gridSize)
        let endSnapped = CGPoint(x: round(end.x / gridSize) * gridSize, y: round(end.y / gridSize) * gridSize)

        // Create a grid representation
        let gridWidth = Int(max(startSnapped.x, endSnapped.x) / gridSize) + 1
        let gridHeight = Int(max(startSnapped.y, endSnapped.y) / gridSize) + 1
        var grid = Array(repeating: Array(repeating: 0, count: gridWidth), count: gridHeight)

        // Mark existing wires on the grid
        for wire in existingWires {
            for i in 0..<wire.path.count - 1 {
                let start = wire.path[i]
                let end = wire.path[i + 1]
                markWireOnGrid(&grid, from: start, to: end, gridSize: gridSize)
            }
        }

        // Perform A* pathfinding with a timeout
        let path = aStarPathfinding(grid: grid, start: startSnapped, end: endSnapped, gridSize: gridSize, timeout: 1.0)
        return path
    }

    private static func markWireOnGrid(_ grid: inout [[Int]], from start: CGPoint, to end: CGPoint, gridSize: CGFloat) {
        let startX = Int(start.x / gridSize)
        let startY = Int(start.y / gridSize)
        let endX = Int(end.x / gridSize)
        let endY = Int(end.y / gridSize)

        let maxX = grid[0].count - 1
        let maxY = grid.count - 1

        if startX == endX {
            let minY = max(0, min(startY, endY))
            let maxY = min(maxY, max(startY, endY))
            if minY <= maxY {
                for y in minY...maxY {
                    grid[y][min(maxX, max(0, startX))] = 1
                }
            }
        } else if startY == endY {
            let minX = max(0, min(startX, endX))
            let maxX = min(maxX, max(startX, endX))
            if minX <= maxX {
                for x in minX...maxX {
                    grid[min(maxY, max(0, startY))][x] = 1
                }
            }
        } else {
            // Handle diagonal lines if needed
            let dx = abs(endX - startX)
            let dy = abs(endY - startY)
            let sx = startX < endX ? 1 : -1
            let sy = startY < endY ? 1 : -1
            var err = dx - dy
            
            var x = startX
            var y = startY
            
            while true {
                if x >= 0 && x <= maxX && y >= 0 && y <= maxY {
                    grid[y][x] = 1
                }
                if x == endX && y == endY { break }
                let e2 = 2 * err
                if e2 > -dy {
                    err -= dy
                    x += sx
                }
                if e2 < dx {
                    err += dx
                    y += sy
                }
            }
        }
    }

    private static func aStarPathfinding(grid: [[Int]], start: CGPoint, end: CGPoint, gridSize: CGFloat, timeout: TimeInterval) -> [CGPoint] {
        let startTime = Date()
        let startNode = Node(x: Int(start.x / gridSize), y: Int(start.y / gridSize), f: 0, g: 0, h: 0)
        let endNode = Node(x: Int(end.x / gridSize), y: Int(end.y / gridSize), f: 0, g: 0, h: 0)

        var openSet = Set<Node>()
        var closedSet = Set<Node>()
        openSet.insert(startNode)

        var cameFrom = [Node: Node]()

        while !openSet.isEmpty {
            if Date().timeIntervalSince(startTime) > timeout {
                print("Pathfinding timeout reached")
                return [start, end] // Return direct path if timeout is reached
            }

            let current = openSet.min(by: { $0.f < $1.f })!
            if current == endNode {
                return reconstructPath(cameFrom: cameFrom, current: current, gridSize: gridSize)
            }

            openSet.remove(current)
            closedSet.insert(current)

            for var neighbor in getNeighbors(node: current, grid: grid) {
                if closedSet.contains(neighbor) {
                    continue
                }

                let tentativeG = current.g + 1

                if !openSet.contains(neighbor) {
                    openSet.insert(neighbor)
                } else if tentativeG >= neighbor.g {
                    continue
                }

                neighbor.parent = (current.x, current.y)
                neighbor.g = tentativeG
                neighbor.h = manhattanDistance(from: neighbor, to: endNode)
                neighbor.f = neighbor.g + neighbor.h

                cameFrom[neighbor] = current
                
                if let existingIndex = openSet.firstIndex(of: neighbor) {
                    openSet.remove(at: existingIndex)
                }
                openSet.insert(neighbor)
            }
        }

        // If no path is found, return a direct line
        return [start, end]
    }

    private static func getNeighbors(node: Node, grid: [[Int]]) -> [Node] {
        let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
        var neighbors = [Node]()

        for (dx, dy) in directions {
            let newX = node.x + dx
            let newY = node.y + dy

            if newX >= 0 && newX < grid[0].count && newY >= 0 && newY < grid.count && grid[newY][newX] == 0 {
                neighbors.append(Node(x: newX, y: newY, f: 0, g: 0, h: 0))
            }
        }

        return neighbors
    }

    private static func manhattanDistance(from: Node, to: Node) -> Int {
        return abs(from.x - to.x) + abs(from.y - to.y)
    }

    private static func reconstructPath(cameFrom: [Node: Node], current: Node, gridSize: CGFloat) -> [CGPoint] {
        var path = [current]
        var currentNode = current

        while let parent = cameFrom[currentNode] {
            path.append(parent)
            currentNode = parent
        }

        return path.reversed().map { CGPoint(x: CGFloat($0.x) * gridSize, y: CGFloat($0.y) * gridSize) }
    }
}

struct SelectedTerminal: Equatable {
    let componentID: UUID
    let isLeftTerminal: Bool
}