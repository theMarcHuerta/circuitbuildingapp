//
//  ContentView.swift
//  E40M Circuit Solver
//
//  Created by Marc Huerta on 9/19/24.
//

import SwiftUI

struct ContentView: View {
    @State private var components: [Component] = []
    @State private var wires: [Wire] = []
    @State private var selectedTerminal: SelectedTerminal?
    @State private var previousSelectedTerminal: SelectedTerminal?
    @State private var currentDrag: Component?
    @State private var dropLocation: CGPoint?

    @State private var debugMessage: String = ""

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ComponentLibraryView()
                    .frame(width: geometry.size.width * 0.3)
                ZStack {
                    GridView()
                    ForEach(components) { component in
                        ComponentView(component: component, selectedTerminal: $selectedTerminal)
                            .position(component.position)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if let index = components.firstIndex(where: { $0.id == component.id }) {
                                            let newPosition = snapToGrid(value.location)
                                            components[index].position = newPosition
                                            components[index].leftTerminal.position = CGPoint(x: newPosition.x - 40, y: newPosition.y)
                                            components[index].rightTerminal.position = CGPoint(x: newPosition.x + 40, y: newPosition.y)
                                            currentDrag = components[index]
                                            updateConnectedWires(for: components[index])
                                        }
                                    }
                                    .onEnded { _ in
                                        currentDrag = nil
                                    }
                            )
                    }
                    ForEach(wires) { wire in
                        WireView(wire: wire)
                    }
                }
                .frame(width: geometry.size.width * 0.7, height: geometry.size.height)
                .background(Color.white)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if let currentDrag = currentDrag {
                                if let index = components.firstIndex(where: { $0.id == currentDrag.id }) {
                                    let newPosition = snapToGrid(value.location)
                                    components[index].position = newPosition
                                    components[index].leftTerminal.position = CGPoint(x: newPosition.x - 40, y: newPosition.y)
                                    components[index].rightTerminal.position = CGPoint(x: newPosition.x + 40, y: newPosition.y)
                                    updateConnectedWires(for: components[index])
                                }
                            }
                        }
                        .onEnded { _ in
                            currentDrag = nil
                        }
                )
                .onDrop(of: ["public.text"], isTargeted: nil) { providers, location in
                    self.dropLocation = location
                    _ = providers.first?.loadObject(ofClass: String.self) { string, _ in
                        if let string = string, let dropLocation = self.dropLocation {
                            let newComponent = Component(type: string, position: snapToGrid(dropLocation))
                            components.append(newComponent)
                            self.dropLocation = nil
                        }
                    }
                    return true
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: selectedTerminal) { _, newValue in
            handleWireCreation()
        }
    }

    private func handleWireCreation() {
        debugMessage = "Handling wire creation..."
        guard let currentTerminal = selectedTerminal else {
            previousSelectedTerminal = nil
            debugMessage = "No current terminal selected"
            return
        }

        if let previousTerminal = previousSelectedTerminal {
            debugMessage = "Attempting to create wire..."
            // We have two selected terminals, create a wire
            guard let startComponentIndex = components.firstIndex(where: { $0.id == previousTerminal.componentID }),
                  let endComponentIndex = components.firstIndex(where: { $0.id == currentTerminal.componentID }),
                  startComponentIndex != endComponentIndex else {
                // Reset if same component or component not found
                previousSelectedTerminal = currentTerminal
                debugMessage = "Invalid component selection"
                return
            }

            let startComponent = components[startComponentIndex]
            let endComponent = components[endComponentIndex]
            let startPoint = previousTerminal.isLeftTerminal ? startComponent.leftTerminal.position : startComponent.rightTerminal.position
            let endPoint = currentTerminal.isLeftTerminal ? endComponent.leftTerminal.position : endComponent.rightTerminal.position

            debugMessage = "Calculating wire path..."
            let newWire = Wire(startComponentID: startComponent.id,
                               endComponentID: endComponent.id,
                               startIsLeft: previousTerminal.isLeftTerminal,
                               endIsLeft: currentTerminal.isLeftTerminal,
                               startPoint: startPoint,
                               endPoint: endPoint,
                               existingWires: wires)
        
            // Check if the wire path is valid (more than just start and end points)
            if newWire.path.count > 2 {
                wires.append(newWire)

                // Update component connections
                components[startComponentIndex].connections.append(endComponent.id)
                components[endComponentIndex].connections.append(startComponent.id)
                debugMessage = "Wire created successfully"
            } else {
                debugMessage = "Unable to create a valid wire path"
            }

            // Reset selections
            previousSelectedTerminal = nil
            selectedTerminal = nil
        } else {
            // This is the first selected terminal
            previousSelectedTerminal = currentTerminal
            debugMessage = "First terminal selected"
        }
    }

    private func updateConnectedWires(for component: Component) {
        wires = wires.compactMap { wire in
            if wire.startComponentID == component.id || wire.endComponentID == component.id {
                guard let startComponent = components.first(where: { $0.id == wire.startComponentID }),
                      let endComponent = components.first(where: { $0.id == wire.endComponentID }) else {
                    return nil // Remove the wire if one of its components no longer exists
                }
                let startPoint = wire.startIsLeft ? startComponent.leftTerminal.position : startComponent.rightTerminal.position
                let endPoint = wire.endIsLeft ? endComponent.leftTerminal.position : endComponent.rightTerminal.position
                return Wire(startComponentID: wire.startComponentID,
                            endComponentID: wire.endComponentID,
                            startIsLeft: wire.startIsLeft,
                            endIsLeft: wire.endIsLeft,
                            startPoint: startPoint,
                            endPoint: endPoint,
                            existingWires: wires.filter { $0.id != wire.id })
            }
            return wire
        }
    }

    private func snapToGrid(_ location: CGPoint) -> CGPoint {
        let gridSize: CGFloat = 20
        let maxX = CGFloat(GridView.columns - 1) * gridSize
        let maxY = CGFloat(GridView.rows - 1) * gridSize
        let x = min(max(round(location.x / gridSize) * gridSize, 0), maxX)
        let y = min(max(round(location.y / gridSize) * gridSize, 0), maxY)
        return CGPoint(x: x, y: y)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
