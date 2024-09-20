import SwiftUI

struct ComponentView: View {
    let component: Component
    @Binding var selectedTerminal: SelectedTerminal?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 45, height: 15)
                .cornerRadius(2)
            
            Text(component.type)
                .font(.system(size: 8))
                .foregroundColor(.black)
            
            // Left terminal
            Circle()
                .fill(terminalColor(isLeft: true))
                .frame(width: 6, height: 6)
                .offset(x: -22.5, y: 0)
                .onTapGesture {
                    handleTerminalTap(isLeft: true)
                }
            
            // Right terminal
            Circle()
                .fill(terminalColor(isLeft: false))
                .frame(width: 6, height: 6)
                .offset(x: 22.5, y: 0)
                .onTapGesture {
                    handleTerminalTap(isLeft: false)
                }
        }
        .offset(x: 7.5, y: 7.5)  // Offset to align with grid intersections
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
            self.selectedTerminal = nil
        } else {
            self.selectedTerminal = SelectedTerminal(componentID: component.id, isLeftTerminal: isLeft)
        }
    }
}