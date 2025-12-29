import SwiftUI

struct BackgammonNamesView: View {

    // Compatibilidad: si alguna pantalla te llama con config, lo soportamos.
    // (No lo usamos todavía en este checkpoint UX, pero lo dejamos para no romper llamadas.)
    let config: BackgammonConfig?

    init(config: BackgammonConfig? = nil) {
        self.config = config
    }

    @State private var p1: String = ""
    @State private var p2: String = ""

    @State private var lockedP1: String = ""
    @State private var lockedP2: String = ""

    @State private var colors: BackgammonColorAssignment?
    @State private var startResult: BackgammonStartDiceResult?

    @State private var goColors = false
    @State private var goDice = false
    @State private var goTurn = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case p1, p2
    }

    // MARK: - Validation

    private var p1Trim: String { trimmed(p1) }
    private var p2Trim: String { trimmed(p2) }

    // ✅ Solo habilita con 4+ letras en ambos nombres
    private var isValid: Bool {
        p1Trim.count >= 4 && p2Trim.count >= 4
    }

    var body: some View {
        VStack(spacing: 14) {

            Text("Jugadores")
                .font(.title.bold())
                .padding(.top, 10)

            VStack(spacing: 10) {
                TextField("Jugador 1", text: $p1)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .textContentType(.name)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .p1)
                    .onSubmit { focusedField = .p2 }

                TextField("Jugador 2", text: $p2)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .textContentType(.name)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .p2)
                    .onSubmit {
                        if isValid { startFlow() }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            Spacer()

            Button {
                startFlow()
            } label: {
                Text("Continuar")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            .disabled(!isValid)
        }
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // para que sea cómodo al entrar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                focusedField = .p1
            }
        }

        // 1) Nombres -> Ruleta de colores
        .navigationDestination(isPresented: $goColors) {
            BackgammonColorRouletteView(
                player1Name: lockedP1,
                player2Name: lockedP2,
                onContinue: { assignedColors in
                    self.colors = assignedColors
                    self.goColors = false
                    self.goDice = true
                }
            )
        }

        // 2) Colores -> Ruleta de dados iniciales
        .navigationDestination(isPresented: $goDice) {
            if let colors {
                BackgammonDiceRouletteView(
                    colors: colors,
                    onContinue: { result in
                        self.startResult = result
                        self.goDice = false
                        self.goTurn = true
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

        // 3) Dados -> Tablero (estable)
        .navigationDestination(isPresented: $goTurn) {
            if let colors, let startResult {
                BackgammonBoardView(colors: colors, startResult: startResult)
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

    // MARK: - Actions

    private func startFlow() {
        lockedP1 = sanitizeToUpper(p1, fallback: "JUGADOR 1")
        lockedP2 = sanitizeToUpper(p2, fallback: "JUGADOR 2")
        goColors = true
    }

    // MARK: - Helpers

    private func sanitizeToUpper(_ s: String, fallback: String) -> String {
        let t = trimmed(s)
        return t.isEmpty ? fallback : t.uppercased()
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
