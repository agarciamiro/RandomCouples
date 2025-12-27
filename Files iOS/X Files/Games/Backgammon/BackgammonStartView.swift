import SwiftUI
import Foundation

struct BackgammonStartView: View {

    private enum Step {
        case players
        case colors
        case startDice
        case board
    }

    @State private var step: Step = .players

    @State private var p1: String = ""
    @State private var p2: String = ""

    @State private var lockedP1: String = "Jugador 1"
    @State private var lockedP2: String = "Jugador 2"

    @State private var colorAssignment: BackgammonColorAssignment? = nil
    @State private var startDiceResult: BackgammonStartDiceResult? = nil

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .players:
                playersScreen

            case .colors:
                colorsScreen

            case .startDice:
                startDiceScreen

            case .board:
                boardScreen
            }
        }
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pantallas

    private var playersScreen: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 12)

            Text("Jugadores")
                .font(.largeTitle.bold())

            Text("Ingresa 2 nombres")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                TextField("Jugador 1", text: $p1)
                    .textFieldStyle(.roundedBorder)

                TextField("Jugador 2", text: $p2)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Spacer()

            Button {
                lockedP1 = normalized(p1, fallback: "Jugador 1")
                lockedP2 = normalized(p2, fallback: "Jugador 2")
                step = .colors
            } label: {
                Text("Continuar")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            .disabled(normalized(p1, fallback: "").isEmpty || normalized(p2, fallback: "").isEmpty)
        }
    }

    private var colorsScreen: some View {
        BackgammonColorRouletteView(
            player1Name: lockedP1,
            player2Name: lockedP2,
            onContinue: { assignment in
                self.colorAssignment = assignment
                self.step = .startDice
            }
        )
    }

    private var startDiceScreen: some View {
        let colors = colorAssignment ?? BackgammonColorAssignment(
            whitePlayer: lockedP1,
            blackPlayer: lockedP2
        )

        return BackgammonDiceRouletteView(
            colors: colors,
            onContinue: { result in
                self.startDiceResult = result
                // ✅ Opción A: directo a Tablero (sin pantalla intermedia)
                self.step = .board
            }
        )
    }

    private var boardScreen: some View {
        let colors = colorAssignment ?? BackgammonColorAssignment(
            whitePlayer: lockedP1,
            blackPlayer: lockedP2
        )

        let start = startDiceResult ?? BackgammonStartDiceResult(
            blackPlayer: colors.blackPlayer,
            whitePlayer: colors.whitePlayer,
            blackDie: 6,
            whiteDie: 1,
            tieCount: 0
        )

        return BackgammonBoardView(colors: colors, startResult: start)
    }

    // MARK: - Helpers

    private func normalized(_ s: String, fallback: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? fallback : t
    }
}
