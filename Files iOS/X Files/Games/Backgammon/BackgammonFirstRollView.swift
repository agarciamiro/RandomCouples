import SwiftUI

/// ✅ STUB COMPATIBLE:
/// Esta pantalla era de un flujo antiguo (FirstRoll -> GameView).
/// La dejamos compilable para no romper el build aunque siga en el proyecto.
///
/// Importante: conserva labels (config/players/assignment) pero los tipos son Any,
/// así cualquier llamada vieja sigue compilando.
struct BackgammonFirstRollView: View {

    init(config: Any? = nil, players: Any? = nil, assignment: Any? = nil) { }

    var body: some View {
        VStack(spacing: 12) {
            Text("Pantalla antigua desactivada")
                .font(.title2.bold())

            Text("Tu flujo actual usa: Ruleta Colores → Ruleta Dados → Tablero.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
