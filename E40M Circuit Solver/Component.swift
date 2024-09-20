import SwiftUI

struct ComponentView: View {
    let component: Component
    @Binding var selectedTerminal: SelectedTerminal?

    var body: some View {
        ZStack {
            Text(component.type)
                .padding()
                .background(Color.gray)
                .cornerRadius(8)
            
            // Left terminal
            Circle()
                .fill(terminalColor(isLeft: true))
                .frame(width: 10, height: 10)
                .offset(x: -40, y: 0)
                .onTapGesture {
                    handleTerminalTap(isLeft: true)
                }
            
            // Right terminal
            Circle()
                .fill(terminalColor(isLeft: false))
                .frame(width: 10, height: 10)
                .offset(x: 40, y: 0)
                .onTapGesture {
                    handleTerminalTap(isLeft: false)
                }
        }
    }

    private func terminalColor(isLeft: Bool) -> Color {
        if let selectedTerminal = selectedTerminal,
           selectedTerminal.componentID == component.id && selectedTerminal.isLeftTerminal == isLeft {
            return .blue
        }
        return .red
    }

    private func handleTerminalTap(isLeft: Bool) {
        if let selectedTerminal = selectedTerminal,
           selectedTerminal.componentID == component.id && selectedTerminal.isLeftTerminal == isLeft {
            // Deselect if tapping the same terminal
            self.selectedTerminal = nil
        } else {
            // Select the tapped terminal
            self.selectedTerminal = SelectedTerminal(componentID: component.id, isLeftTerminal: isLeft)
        }
    }
}