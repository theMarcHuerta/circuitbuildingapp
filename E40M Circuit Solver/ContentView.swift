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
    @State private var showComponentLibrary = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GridView()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / self.lastScale
                                self.lastScale = value
                                let newScale = self.scale * delta
                                self.scale = min(max(newScale, 0.5), 3.0)
                            }
                            .onEnded { _ in
                                self.lastScale = 1.0
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                self.offset = CGSize(
                                    width: self.lastOffset.width + value.translation.width,
                                    height: self.lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                self.lastOffset = self.offset
                            }
                    )
                
                ForEach(wires) { wire in
                    WireView(wire: wire)
                        .scaleEffect(scale)
                        .offset(offset)
                }
                
                ForEach(components) { component in
                    ComponentView(component: component, selectedTerminal: $selectedTerminal)
                        .position(component.position)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if let index = components.firstIndex(where: { $0.id == component.id }) {
                                        let newPosition = snapToGrid(CGPoint(
                                            x: (value.location.x - offset.width) / scale,
                                            y: (value.location.y - offset.height) / scale
                                        ))
                                        components[index].position = newPosition
                                        components[index].leftTerminal.position = CGPoint(x: newPosition.x - 15, y: newPosition.y)
                                        components[index].rightTerminal.position = CGPoint(x: newPosition.x + 15, y: newPosition.y)
                                        currentDrag = components[index]
                                        updateConnectedWires(for: components[index])
                                    }
                                }
                                .onEnded { _ in
                                    currentDrag = nil
                                }
                        )
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showComponentLibrary.toggle()
                            }
                        }) {
                            Image(systemName: showComponentLibrary ? "chevron.up" : "chevron.down")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    if showComponentLibrary {
                        ComponentLibraryView()
                            .frame(width: geometry.size.width * 0.2, height: geometry.size.height * 0.6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .transition(.move(edge: .top))
                            .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.3)
                    }
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.white)
            .onDrop(of: ["public.text"], isTargeted: nil) { providers, location in
                self.dropLocation = CGPoint(
                    x: (location.x - offset.width) / scale,
                    y: (location.y - offset.height) / scale
                )
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
        .onChange(of: selectedTerminal) { _, newValue in
            handleWireCreation()
        }
    }

    private func handleWireCreation() {
        guard let currentTerminal = selectedTerminal else {
            previousSelectedTerminal = nil
            return
        }

        if let previousTerminal = previousSelectedTerminal {
            guard let startComponentIndex = components.firstIndex(where: { $0.id == previousTerminal.componentID }),
                  let endComponentIndex = components.firstIndex(where: { $0.id == currentTerminal.componentID }),
                  startComponentIndex != endComponentIndex else {
                previousSelectedTerminal = currentTerminal
                return
            }

            let startComponent = components[startComponentIndex]
            let endComponent = components[endComponentIndex]
            let startPoint = previousTerminal.isLeftTerminal ? startComponent.leftTerminal.position : startComponent.rightTerminal.position
            let endPoint = currentTerminal.isLeftTerminal ? endComponent.leftTerminal.position : endComponent.rightTerminal.position

            let newWire = Wire(startComponentID: startComponent.id,
                               endComponentID: endComponent.id,
                               startIsLeft: previousTerminal.isLeftTerminal,
                               endIsLeft: currentTerminal.isLeftTerminal,
                               startPoint: startPoint,
                               endPoint: endPoint,
                               existingWires: wires,
                               components: components)
            wires.append(newWire)

            components[startComponentIndex].connections.append(endComponent.id)
            components[endComponentIndex].connections.append(startComponent.id)

            previousSelectedTerminal = nil
            selectedTerminal = nil
        } else {
            previousSelectedTerminal = currentTerminal
        }
    }

    private func updateConnectedWires(for component: Component) {
        wires = wires.compactMap { wire in
            if wire.startComponentID == component.id || wire.endComponentID == component.id {
                guard let startComponent = components.first(where: { $0.id == wire.startComponentID }),
                      let endComponent = components.first(where: { $0.id == wire.endComponentID }) else {
                    return nil
                }
                let startPoint = wire.startIsLeft ? startComponent.leftTerminal.position : startComponent.rightTerminal.position
                let endPoint = wire.endIsLeft ? endComponent.leftTerminal.position : endComponent.rightTerminal.position
                return Wire(startComponentID: wire.startComponentID,
                            endComponentID: wire.endComponentID,
                            startIsLeft: wire.startIsLeft,
                            endIsLeft: wire.endIsLeft,
                            startPoint: startPoint,
                            endPoint: endPoint,
                            existingWires: wires.filter { $0.id != wire.id },
                            components: components)
            }
            return wire
        }
    }

    private func snapToGrid(_ location: CGPoint) -> CGPoint {
        let gridSize: CGFloat = 10
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
