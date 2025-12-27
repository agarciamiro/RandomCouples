import SwiftUI

struct BackgammonFirstRollView: View {

    let config: BackgammonConfig
    let players: BackgammonPlayers
    let assignment: BackgammonAssignment

    @State private var lastP1: Int? = nil
    @State private var lastP2: Int? = nil
    @State private var tieMultiplier: Int = 1
    @State private var resolved: BackgammonOpening? = nil
    @State private var rolling = false

    var body: some View {
        VStack(spacing: 14) {

            Text("Inicio de partida")
                .font(.title2.bold())

            Text("Cada jugador tira 1 dado. Si empatan, se repite.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)

            VStack(spacing: 10) {
                rollCard(name: players.p1, value: lastP1, color: assignment.p1Color)
                rollCard(name: players.p2, value: lastP2, color: assignment.p2Color)
            }
            .padding(.horizontal, 16)

            if tieMultiplier > 1 && resolved == nil {
                Text("Empate: multiplicador x\(tieMultiplier)")
                    .font(.footnote.bold())
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.25))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            }

            Spacer()

            Button {
                tirar()
            } label: {
                Text(rolling ? "Tirando..." : "Tirar")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .disabled(rolling || resolved != nil)

            if let opening = resolved {
                // ✅ .player1 (no .playerl)
                let starterName = (opening.starter == .player1) ? players.p1 : players.p2

                Text("Empieza: \(starterName) — Dados iniciales: \(opening.openingDice[0]) + \(opening.openingDice[1])")
                    .font(.footnote.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                NavigationLink {
                    BackgammonGameView(
                        config: config,
                        players: players,
                        assignment: assignment,
                        opening: opening
                    )
                } label: {
                    Text("Comenzar juego")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tirar() {
        rolling = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
            // Mantengo tu engine si existe
            let r = BackgammonDiceEngine.rollOpeningDiceDistinct()

            lastP1 = r.p1
            lastP2 = r.p2

            // Mapear dados a NEGRAS/BLANCAS según assignment
            let blackDie: Int
            let whiteDie: Int
            if assignment.p1Color == .black {
                blackDie = r.p1
                whiteDie = r.p2
            } else {
                blackDie = r.p2
                whiteDie = r.p1
            }

            // tieMultiplier lo llevas visual, tieCount lo guardamos como tieMultiplier-1
            let start = BackgammonStartDiceResult(blackDie: blackDie, whiteDie: whiteDie, tieCount: max(0, tieMultiplier - 1))

            resolved = BackgammonOpening(
                config: config,
                players: players,
                assignment: assignment,
                startResult: start
            )

            rolling = false
        })
    }

    private func rollCard(name: String, value: Int?, color: BGColor) -> some View {
        HStack {
            Text(name).font(.subheadline.bold())
            Spacer()
            Text(value == nil ? "—" : "\(value!)")
                .font(.title3.bold())
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
    }
}
