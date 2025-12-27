import SwiftUI

struct BackgammonNamesView: View {

    let config: BackgammonConfig

    @State private var p1: String = ""
    @State private var p2: String = ""

    @State private var lockedP1: String = ""
    @State private var lockedP2: String = ""

    @State private var colors: BackgammonColorAssignment?
    @State private var startResult: BackgammonStartDiceResult?

    @State private var goColors = false
    @State private var goDice = false
    @State private var goTurn = false

    var body: some View {
        VStack(spacing: 14) {

            Text("Jugadores")
                .font(.title.bold())
                .padding(.top, 10)

            VStack(spacing: 10) {
                TextField("Jugador 1", text: $p1)
                    .textFieldStyle(.roundedBorder)
                TextField("Jugador 2", text: $p2)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            Spacer()

            Button {
                lockedP1 = normalized(p1, fallback: "Jugador 1")
                lockedP2 = normalized(p2, fallback: "Jugador 2")
                goColors = true
            } label: {
                Text("Continuar")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            .disabled(normalized(p1, fallback: "").isEmpty || normalized(p2, fallback: "").isEmpty)

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
                    self.goDice = true
                }
            )
        }

        // 2) Colores -> Ruleta de dados
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
            }
        }

        // 3) Dados -> siguiente pantalla (yo lo mando directo al Board, porque es lo más estable)
        .navigationDestination(isPresented: $goTurn) {
            if let colors, let startResult {
                BackgammonBoardView(colors: colors, startResult: startResult)
            }
        }
    }

    private func normalized(_ s: String, fallback: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? fallback : t
    }
}
