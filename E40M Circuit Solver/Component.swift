import SwiftUI

struct ComponentView: View {
    let component: Component
    @Binding var selectedTerminal: SelectedTerminal?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: GridView.gridSize * 5, height: GridView.gridSize * 2)
                .cornerRadius(4)
            
            Text(component.type)
                .font(.system(size: 10))
                .foregroundColor(.black)
            
            // Left terminal
            Circle()
                .fill(terminalColor(isLeft: true))
                .frame(width: 8, height: 8)
                .offset(x: -GridView.gridSize * 2, y: 0)
                .onTapGesture {
                    handleTerminalTap(isLeft: true)
                }
            
            // Right terminal
            Circle()
                .fill(terminalColor(isLeft: false))
                .frame(width: 8, height: 8)
                .offset(x: GridView.gridSize * 2, y: 0)
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
            self.selectedTerminal = nil
        } else {
            self.selectedTerminal = SelectedTerminal(componentID: component.id, isLeftTerminal: isLeft)
        }
    }
}