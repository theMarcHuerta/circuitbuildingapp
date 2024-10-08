//
//  ContentView.swift
//  E40M Circuit Solver
//
//  Created by Marc Huerta on 9/19/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var components: [Component] = []
    @State private var wires: [Wire] = []
    @State private var selectedTerminal: SelectedTerminal?
    @State private var previousSelectedTerminal: SelectedTerminal?
    @State private var currentDrag: Component?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var viewportSize: CGSize = .zero
    @State private var showComponentLibrary = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GridView()
                    .scaleEffect(scale)
                    .offset(offset)
                
                ForEach(wires) { wire in
                    WireView(wire: wire)
                        .scaleEffect(scale)
                        .offset(offset)
                }
                
                ForEach(components) { component in
                    ComponentView(component: component, selectedTerminal: $selectedTerminal)
                        .position(scaledPosition(component.position))
                        .scaleEffect(scale)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if let index = components.firstIndex(where: { $0.id == component.id }) {
                                        let newPosition = snapToGrid(unscaledPosition(value.location))
                                        components[index].position = newPosition
                                        components[index].leftTerminal.position = CGPoint(x: newPosition.x - GridView.gridSize * 2, y: newPosition.y)
                                        components[index].rightTerminal.position = CGPoint(x: newPosition.x + GridView.gridSize * 2, y: newPosition.y)
                                        currentDrag = components[index]
                                        updateConnectedWires(for: components[index])
                                    }
                                }
                                .onEnded { _ in
                                    currentDrag = nil
                                    updateAllWires()
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
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / self.lastScale
                        self.lastScale = value
                        let newScale = self.scale * delta
                        self.scale = min(max(newScale, 0.5), 5.0)
                        updateAllComponentPositions()
                        updateAllWires()
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
                        updateAllWires()
                    }
                    .onEnded { _ in
                        self.lastOffset = self.offset
                    }
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.white)
            .onDrop(of: ["public.text"], isTargeted: nil) { providers, location in
                let dropLocation = unscaledPosition(location)
                _ = providers.first?.loadObject(ofClass: String.self) { string, _ in
                    if let string = string {
                        let snappedLocation = snapToGrid(dropLocation)
                        let newComponent = Component(type: string, position: snappedLocation)
                        components.append(newComponent)
                    }
                }
                return true
            }
            .onAppear {
                viewportSize = geometry.size
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onChange(of: selectedTerminal) { _, newValue in
            handleWireCreation()
        }
    }

    private func scaledPosition(_ position: CGPoint) -> CGPoint {
        CGPoint(
            x: position.x * scale + offset.width,
            y: position.y * scale + offset.height
        )
    }

    private func unscaledPosition(_ position: CGPoint) -> CGPoint {
        CGPoint(
            x: (position.x - offset.width) / scale,
            y: (position.y - offset.height) / scale
        )
    }

    private func snapToGrid(_ location: CGPoint) -> CGPoint {
        let x = round(location.x / GridView.gridSize) * GridView.gridSize
        let y = round(location.y / GridView.gridSize) * GridView.gridSize
        return CGPoint(x: x, y: y)
    }

    private func updateAllComponentPositions() {
        for index in components.indices {
            components[index].position = snapToGrid(components[index].position)
            components[index].leftTerminal.position = CGPoint(x: components[index].position.x - 22.5, y: components[index].position.y)
            components[index].rightTerminal.position = CGPoint(x: components[index].position.x + 22.5, y: components[index].position.y)
        }
    }

    private func updateAllWires() {
        wires = wires.map { updateWire($0) }
    }

    private func updateWire(_ wire: Wire) -> Wire {
        guard let startComponent = components.first(where: { $0.id == wire.startComponentID }),
              let endComponent = components.first(where: { $0.id == wire.endComponentID }) else {
            return wire
        }
        let startPoint = wire.startIsLeft ? startComponent.leftTerminal.position : startComponent.rightTerminal.position
        let endPoint = wire.endIsLeft ? endComponent.leftTerminal.position : endComponent.rightTerminal.position
        return Wire(startComponentID: wire.startComponentID,
                    endComponentID: wire.endComponentID,
                    startIsLeft: wire.startIsLeft,
                    endIsLeft: wire.endIsLeft,
                    startPoint: startPoint,
                    endPoint: endPoint,
                    scale: scale,
                    offset: offset)
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
                               scale: scale,
                               offset: offset)
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
        wires = wires.map { wire in
            if wire.startComponentID == component.id || wire.endComponentID == component.id {
                return updateWire(wire)
            }
            return wire
        }
    }
}
