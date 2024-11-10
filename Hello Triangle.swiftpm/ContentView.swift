import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Yep")
            MetalView()
                .frame(width: 200, height: 200)
                .border(.gray, width: 1)
        }
    }
    
}
