import SwiftUI

/// ✅ STUB COMPATIBLE:
/// View antigua (GameView). Se deja como placeholder para que el build no se rompa.
///
/// Mantiene labels y acepta Any para que llamadas viejas no fallen.
struct BackgammonGameView: View {

    init(config: Any? = nil, players: Any? = nil, assignment: Any? = nil, opening: Any? = nil) { }

    var body: some View {
        VStack(spacing: 12) {
            Text("BackgammonGameView (antiguo) desactivado")
                .font(.title3.bold())

            Text("El juego actual sigue el flujo nuevo (ruletas → tablero).")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding()
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)
    }
}
