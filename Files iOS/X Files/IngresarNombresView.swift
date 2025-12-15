import SwiftUI

// -----------------------------------------------
// Normaliza nombres: "  lUiS " → "Luis"
// -----------------------------------------------
func normalizarNombre(_ texto: String) -> String {
    let trimmed = texto.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "" }

    let lower = trimmed.lowercased()
    let first = lower.prefix(1).uppercased()
    let rest = lower.dropFirst()
    return first + rest
}

// -----------------------------------------------
// Vista principal para ingresar nombres
// -----------------------------------------------
struct IngresarNombresView: View {

    let teamCount: Int                // viene de PartidaView
    var maxJugadores: Int { teamCount * 2 }

    @State private var nombres: [String]
    @State private var mostrarAlertaDuplicados = false

    init(teamCount: Int) {
        self.teamCount = teamCount
        let max = teamCount * 2
        _nombres = State(initialValue: Array(repeating: "", count: max))
    }

    // Nombres válidos y normalizados
    var jugadoresValidos: [String] {
        nombres
            .map { normalizarNombre($0) }
            .filter { !$0.isEmpty }
    }

    // Detectar duplicados
    var hayDuplicados: Bool {
        let lista = jugadoresValidos
        return Set(lista).count != lista.count
    }

    var body: some View {
        VStack(spacing: 20) {

            Text("Ingresar jugadores")
                .font(.title.bold())

            List {
                ForEach(nombres.indices, id: \.self) { index in
                    TextField(
                        "Jugador \(index + 1)",
                        text: Binding(
                            get: { nombres[index] },
                            set: { nuevo in
                                nombres[index] = normalizarNombre(nuevo)
                            }
                        )
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }
            }

            // ------------------------------------------------
            // BOTÓN PARA CONTINUAR → RULETAVIEW
            // ------------------------------------------------
            NavigationLink(
                destination: RuletaView(jugadores: jugadoresValidos)
            ) {
                Text("Continuar → Ruleta")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(!botonHabilitado ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!botonHabilitado)
            .simultaneousGesture(TapGesture().onEnded {
                if hayDuplicados { mostrarAlertaDuplicados = true }
            })

            Spacer()
        }
        .padding()
        .alert("Hay nombres duplicados", isPresented: $mostrarAlertaDuplicados) {
            Button("Entendido", role: .cancel) { }
        }
    }

    // ------------------------------------------------
    // Reglas para habilitar el botón
    // ------------------------------------------------
    var botonHabilitado: Bool {
        jugadoresValidos.count == maxJugadores && !hayDuplicados
    }
}
