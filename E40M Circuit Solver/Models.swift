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
        self.leftTerminal = Terminal(componentID: id, position: CGPoint(x: position.x - 22.5, y: position.y))
        self.rightTerminal = Terminal(componentID: id, position: CGPoint(x: position.x + 22.5, y: position.y))
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

    init(startComponentID: UUID, endComponentID: UUID, startIsLeft: Bool, endIsLeft: Bool, startPoint: CGPoint, endPoint: CGPoint, components: [Component]) {
        self.startComponentID = startComponentID
        self.endComponentID = endComponentID
        self.startIsLeft = startIsLeft
        self.endIsLeft = endIsLeft
        self.path = Wire.calculatePath(from: startPoint, to: endPoint, avoidingComponents: components)
    }

    static func calculatePath(from start: CGPoint, to end: CGPoint, avoidingComponents components: [Component]) -> [CGPoint] {
        let gridSize: CGFloat = 15
        let startSnapped = CGPoint(x: round(start.x / gridSize) * gridSize, y: round(start.y / gridSize) * gridSize)
        let endSnapped = CGPoint(x: round(end.x / gridSize) * gridSize, y: round(end.y / gridSize) * gridSize)

        var path = [startSnapped]
        var currentPoint = startSnapped

        while currentPoint != endSnapped {
            let dx = endSnapped.x - currentPoint.x
            let dy = endSnapped.y - currentPoint.y

            var nextPoint: CGPoint
            if abs(dx) > abs(dy) {
                nextPoint = CGPoint(x: currentPoint.x + (dx > 0 ? gridSize : -gridSize), y: currentPoint.y)
            } else {
                nextPoint = CGPoint(x: currentPoint.x, y: currentPoint.y + (dy > 0 ? gridSize : -gridSize))
            }

            if !intersectsComponents(from: currentPoint, to: nextPoint, components: components) {
                path.append(nextPoint)
                currentPoint = nextPoint
            } else {
                // Try to go around the component
                let alternatePoint = CGPoint(x: currentPoint.x, y: currentPoint.y + (dy > 0 ? gridSize : -gridSize))
                if !intersectsComponents(from: currentPoint, to: alternatePoint, components: components) {
                    path.append(alternatePoint)
                    currentPoint = alternatePoint
                } else {
                    // If both directions are blocked, try to go the other way
                    let alternatePoint2 = CGPoint(x: currentPoint.x + (dx > 0 ? gridSize : -gridSize), y: currentPoint.y)
                    if !intersectsComponents(from: currentPoint, to: alternatePoint2, components: components) {
                        path.append(alternatePoint2)
                        currentPoint = alternatePoint2
                    } else {
                        // If all directions are blocked, stop routing
                        break
                    }
                }
            }
        }

        path.append(endSnapped)
        return path
    }

    private static func intersectsComponents(from start: CGPoint, to end: CGPoint, components: [Component]) -> Bool {
        let componentRects = components.map { component in
            CGRect(x: component.position.x - 22.5, y: component.position.y - 7.5, width: 45, height: 15)
        }

        for rect in componentRects {
            if lineIntersectsRect(start: start, end: end, rect: rect) {
                return true
            }
        }

        return false
    }

    private static func lineIntersectsRect(start: CGPoint, end: CGPoint, rect: CGRect) -> Bool {
        let minX = min(start.x, end.x)
        let maxX = max(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxY = max(start.y, end.y)

        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)

        if maxX < rect.minX || minX > rect.maxX || maxY < rect.minY || minY > rect.maxY {
            return false
        }

        if rect.contains(start) || rect.contains(end) {
            return true
        }

        if linesIntersect(start1: start, end1: end, lineStart: topLeft, lineEnd: topRight) ||
           linesIntersect(start1: start, end1: end, lineStart: topRight, lineEnd: bottomRight) ||
           linesIntersect(start1: start, end1: end, lineStart: bottomRight, lineEnd: bottomLeft) ||
           linesIntersect(start1: start, end1: end, lineStart: bottomLeft, lineEnd: topLeft) {
            return true
        }

        return false
    }

    private static func linesIntersect(start1: CGPoint, end1: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> Bool {
        let dx1 = end1.x - start1.x
        let dy1 = end1.y - start1.y
        let dx2 = lineEnd.x - lineStart.x
        let dy2 = lineEnd.y - lineStart.y

        let determinant = dx1 * dy2 - dy1 * dx2

        if abs(determinant) < CGFloat.ulpOfOne {
            return false
        }

        let dx3 = start1.x - lineStart.x
        let dy3 = start1.y - lineStart.y

        let t = (dx3 * dy2 - dy3 * dx2) / determinant
        let u = (dx1 * dy3 - dy1 * dx3) / determinant

        return t >= 0 && t <= 1 && u >= 0 && u <= 1
    }
}

struct SelectedTerminal: Equatable {
    let componentID: UUID
    let isLeftTerminal: Bool
}