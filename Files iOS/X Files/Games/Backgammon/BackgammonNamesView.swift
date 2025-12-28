import SwiftUI

struct BackgammonNamesView: View {

    // Compatibilidad: por si alguna pantalla te llama con config
    let config: BackgammonConfig
    init(config: BackgammonConfig = BackgammonConfig()) {
        self.config = config
    }

    @State private var p1: String = ""
    @State private var p2: String = ""

    @State private var lockedP1: String = ""
    @State private var lockedP2: String = ""

    @State private var colors: BackgammonColorAssignment? = nil
    @State private var startResult: BackgammonStartDiceResult? = nil

    @State private var goColors = false
    @State private var goDice = false
    @State private var goTurn = false

    // ✅ Validación: mínimo 4 caracteres reales en cada nombre
    private var isValid: Bool {
        trimmed(p1).count >= 4 && trimmed(p2).count >= 4
    }

    var body: some View {
        VStack(spacing: 18) {

            Spacer(minLength: 10)

            Text("Jugadores")
                .font(.largeTitle.bold())
                .padding(.top, 8)

            VStack(spacing: 12) {
                TextField("Jugador 1", text: $p1)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)

                TextField("Jugador 2", text: $p2)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
            }
            .padding(.horizontal, 16)

            Spacer()

            Button {
                lockedP1 = sanitizeToUpper(p1, fallback: "JUGADOR 1")
                lockedP2 = sanitizeToUpper(p2, fallback: "JUGADOR 2")
                goColors = true
            } label: {
                Text("Continuar")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            .disabled(!isValid)

        }
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)

        // 1) Nombres -> Ruleta de colores
        .navigationDestination(isPresented: $goColors) {
            BackgammonColorRouletteView(
                player1Name: lockedP1,
                player2Name: lockedP2,
                onContinue: { assignedColors in
                    self.colors = assignedColors
                    self.goColors = false
                    DispatchQueue.main.async {
                        self.goDice = true
                    }
                }
            )
        }

        // 2) Colores -> Dados iniciales
        .navigationDestination(isPresented: $goDice) {
            if let colors {
                BackgammonDiceRouletteView(
                    colors: colors,
                    onContinue: { result in
                        self.startResult = result
                        self.goDice = false
                        DispatchQueue.main.async {
                            self.goTurn = true
                        }
                    }
                )
            } else {
                VStack(spacing: 10) {
                    Text("Error de navegación")
                        .font(.headline)
                    Text("No se encontró la asignación de colores.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }

        // 3) Dados iniciales -> TurnDice / Tablero
        .navigationDestination(isPresented: $goTurn) {
            if let colors, let startResult {
                BackgammonTurnDiceView(colors: colors, startResult: startResult)
            } else {
                VStack(spacing: 10) {
                    Text("Error de navegación")
                        .font(.headline)
                    Text("Falta información de inicio.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }

    // MARK: - Helpers

    private func sanitizeToUpper(_ s: String, fallback: String) -> String {
        let cleaned = trimmed(s)
        return cleaned.isEmpty ? fallback : cleaned.uppercased()
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

