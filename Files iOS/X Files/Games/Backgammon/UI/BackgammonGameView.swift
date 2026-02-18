import SwiftUI

struct BackgammonGameView: View {

    let config: BackgammonConfig
    let players: BackgammonPlayers
    let assignment: BackgammonAssignment
    let opening: BackgammonOpening

    @State private var turno: BGSide
    @State private var diceMoves: [Int] = []
    @State private var yaUsoApertura = false

    init(
        config: BackgammonConfig,
        players: BackgammonPlayers,
        assignment: BackgammonAssignment,
        opening: BackgammonOpening
    ) {
        self.config = config
        self.players = players
        self.assignment = assignment
        self.opening = opening
        _turno = State(initialValue: opening.starter)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                header

                cardJugadores

                cardTurno

                cardDados

                // Placeholder IA (si aplica)
                if config.mode == .twoPlayersAdvisorBoth {
                    cardAyudaIA(para: .player1)
                    cardAyudaIA(para: .player2)
                } else if config.mode == .twoPlayersAdvisorHome {
                    cardAyudaIA(para: config.homeSide)
                } else if config.mode == .vsCPU {
                    Text("Modo vs CPU: (próximo) la computadora jugará su turno automáticamente.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // La primera tirada es la apertura
            if !yaUsoApertura {
                diceMoves = opening.openingDice
                yaUsoApertura = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("Partida iniciada (multiplicador x\(opening.tieMultiplier))")
            .font(.footnote.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.78))
            .cornerRadius(14)
    }

    // MARK: - Jugadores

    private var cardJugadores: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jugadores").font(.footnote.bold())

            playerRow(n: 1, name: players.p1, color: assignment.p1Color)
            playerRow(n: 2, name: players.p2, color: assignment.p2Color)

        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private func playerRow(n: Int, name: String, color: BGColor) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(n)) \(name)")
                .font(.subheadline.bold())

            Text(color.titulo)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color == .white ? Color.gray.opacity(0.12) : Color.black.opacity(0.8))
                .foregroundColor(color == .white ? .primary : .white)
                .cornerRadius(10)
        }
    }

    // MARK: - Turno

    private var cardTurno: some View {
        let nombreTurno = (turno == .player1) ? players.p1 : players.p2
        let col = assignment.color(of: turno).titulo

        return VStack(alignment: .leading, spacing: 8) {
            Text("Turno").font(.footnote.bold())

            Text("\(nombreTurno) — \(col)")
                .font(.subheadline.bold())

            HStack(spacing: 10) {
                Button {
                    // 2 dados; dobles = 4 movimientos
                    diceMoves = BackgammonDiceEngine.rollTurnDiceMoves()
                } label: {
                    Text("🎲 Tirar dados")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.92))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button {
                    turno = (turno == .player1) ? .player2 : .player1
                    diceMoves = []
                } label: {
                    Text("Siguiente turno")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.18))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: - Dados

    private var cardDados: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dados / Movimientos").font(.footnote.bold())

            if diceMoves.isEmpty {
                Text("—")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                // ✅ Centrado (aunque el VStack sea alignment: .leading)
                HStack {
                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        ForEach(Array(diceMoves.enumerated()), id: \.offset) { _, v in
                            DiceMoveChip(value: v)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)

                if diceMoves.count == 4, let first = diceMoves.first {
                    Text("Dobles: 4 movimientos de \(first)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Orden no importa: (a,b) = (b,a)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private struct DiceMoveChip: View {
        let value: Int
        var body: some View {
            Text("\(value)")
                .font(.headline.bold())
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .foregroundColor(.primary)
                .cornerRadius(12)
        }
    }

    // MARK: - IA placeholder

    private func cardAyudaIA(para side: BGSide) -> some View {
        let nombre = (side == .player1) ? players.p1 : players.p2
        return VStack(alignment: .leading, spacing: 6) {
            Text("Ayuda IA (placeholder)")
                .font(.footnote.bold())

            Text("Sugerencias para: \(nombre)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Próximo: aquí mostraremos la mejor jugada según los dados actuales.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color.green.opacity(0.10))
        .cornerRadius(16)
    }
}
