import SwiftUI

struct ComponentView: View {
    let component: Component
    @Binding var selectedTerminal: SelectedTerminal?

    var body: some View {
        ZStack {
            Text(component.type)
                .font(.system(size: 10))
                .padding(5)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(5)
            
            // Left terminal
            Circle()
                .fill(terminalColor(isLeft: true))
                .frame(width: 8, height: 8)
                .offset(x: -15, y: 0)
                .onTapGesture {
                    handleTerminalTap(isLeft: true)
                }
            
            // Right terminal
            Circle()
                .fill(terminalColor(isLeft: false))
                .frame(width: 8, height: 8)
                .offset(x: 15, y: 0)
                .onTapGesture {
                    handleTerminalTap(isLeft: false)
                }
        }
        .frame(width: 30, height: 20)
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