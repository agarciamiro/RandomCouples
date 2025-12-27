import SwiftUI

/// Wrapper para mantener compatibilidad con el flujo antiguo.
/// Ahora TODO el flujo (modo → nombres → colores → dados inicio → turnos)
/// está dentro de BackgammonStartView.
struct BackgammonNamesView: View {

    let config: BackgammonConfig

    var body: some View {
        BackgammonStartView()
    }
}
