import SwiftUI

struct ComponentLibraryView: View {
    let components = [
        "Resistor",
        "Capacitor",
        "Inductor",
        "Voltage Source",
        "Current Source",
        "Diode",
        "Transistor",
        "Op-Amp",
        "Motor",
        "Switch"
    ]

    var body: some View {
        VStack {
            Text("Component Library")
                .font(.headline)
                .padding()
            
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(components, id: \.self) { component in
                        ComponentItem(name: component)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 200)
        .background(Color.gray.opacity(0.2))
    }
}

struct ComponentItem: View {
    let name: String
    
    var body: some View {
        Text(name)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .onDrag {
                NSItemProvider(object: name as NSString)
            }
    }
}

struct ComponentLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        ComponentLibraryView()
    }
}