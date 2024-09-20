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
        ScrollView {
            VStack(spacing: 10) {
                Text("Components")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(components, id: \.self) { component in
                    Text(component)
                        .padding(5)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .onDrag {
                            NSItemProvider(object: component as NSString)
                        }
                }
            }
            .padding(5)
        }
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