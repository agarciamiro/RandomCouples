import SwiftUI

struct BackgammonStartView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Backgammon")
                .font(.largeTitle.bold())
            Text("Próximamente. Aquí irá el flujo de Backgammon.")
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)
    }
}
