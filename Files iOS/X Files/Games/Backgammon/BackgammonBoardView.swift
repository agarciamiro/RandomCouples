import SwiftUI
import Foundation

// MARK: - BackgammonBoardView

struct BackgammonBoardView: View {

    // Lo que ya tienes en tu proyecto (porque viene de las ruletas)
    private let colors: BackgammonColorAssignment
    private let start: BackgammonStartDiceResult

    @Environment(\.dismiss) private var dismiss

    // Turno / dados / jugador actual
    @State private var turnNumber: Int
    @State private var currentPiece: Piece
    @State private var die1: Int
    @State private var die2: Int

    // Tablero (solo posiciones 1...24)
    @State private var board: BackgammonBoard

    // MARK: - Inits (para que calce con tus llamadas actuales sin tocar nada)

    init(colors: BackgammonColorAssignment, startResult: BackgammonStartDiceResult) {
        self.colors = colors
        self.start = startResult

        let starter: Piece = (startResult.blackDie > startResult.whiteDie) ? .black : .white
        let major = max(startResult.blackDie, startResult.whiteDie)
        let minor = min(startResult.blackDie, startResult.whiteDie)

        _turnNumber = State(initialValue: 1)
        _currentPiece = State(initialValue: starter)
        _die1 = State(initialValue: major)
        _die2 = State(initialValue: minor)
        _board = State(initialValue: .standardSetup())
    }

    init(startResult: BackgammonStartDiceResult, colors: BackgammonColorAssignment) {
        self.init(colors: colors, startResult: startResult)
    }

    init(colors: BackgammonColorAssignment, result: BackgammonStartDiceResult) {
        self.init(colors: colors, startResult: result)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // Banner azul
                banner
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                // Card header turno
                turnHeaderCard
                    .padding(.horizontal, 16)

                // Tablero
                boardCard
                    .padding(.horizontal, 16)

                VStack(spacing: 6) {
                    Text("Setup estándar cargado (sin movimientos aún).")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text("DEBUG: NEGRAS=\(colors.blackPlayer) · BLANCAS=\(colors.whitePlayer)")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.9))
                }
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
        }
        .navigationTitle("Tablero")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cerrar") { dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                nextTurn()
            } label: {
                Text("Continuar (Siguiente turno)")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 18)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - UI Pieces

    private var banner: some View {
        HStack(spacing: 10) {
            Image(systemName: "squares.leading.rectangle")
                .font(.headline)
            Text("TABLERO (24 posiciones)")
                .font(.subheadline.bold())
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var turnHeaderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Turno \(turnNumber)")
                .font(.title3.bold())

            HStack(spacing: 10) {
                Text("Juega:")
                    .font(.headline)

                piecePill(currentPiece)
            }

            // ✅ mini-ayuda dirección
            Text(directionHelpText)
                .font(.footnote)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                diceBox(die1)
                Text("+")
                    .font(.title3.bold())
                    .foregroundColor(.secondary)
                diceBox(die2)

                Spacer()

                if die1 == die2 {
                    Text("DOBLES")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.20))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func diceBox(_ value: Int) -> some View {
        Text("\(value)")
            .font(.title2.bold())
            .frame(width: 56, height: 56)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func piecePill(_ piece: Piece) -> some View {
        let label = (piece == .white) ? "BLANCAS" : "NEGRAS"
        let bg = (piece == .white) ? Color.black.opacity(0.12) : Color.black.opacity(0.85)
        let fg = (piece == .white) ? Color.primary : Color.white

        return Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(bg)
            .foregroundColor(fg)
            .clipShape(Capsule())
    }

    private var boardCard: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let spacing: CGFloat = 6
                let slotWidth = floor((totalWidth - spacing * 11) / 12)

                VStack(spacing: 14) {

                    // Top row: 24 -> 13
                    BoardRow(
                        title: "24 → 13",
                        points: Array(stride(from: 24, through: 13, by: -1)),
                        slotWidth: slotWidth,
                        spacing: spacing,
                        board: board
                    )

                    // Bottom row: 12 -> 1
                    BoardRow(
                        title: "12 → 1",
                        points: Array(stride(from: 12, through: 1, by: -1)),
                        slotWidth: slotWidth,
                        spacing: spacing,
                        board: board
                    )
                }
                .frame(width: totalWidth)
            }
            .frame(height: 220)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Logic

    private var directionHelpText: String {
        if currentPiece == .white {
            return "BLANCAS: 24 → 1"
        } else {
            return "NEGRAS: 1 → 24"
        }
    }

    private func nextTurn() {
        // (Por ahora solo rota turno + tira dados; la lógica de movimientos la vemos luego)
        turnNumber += 1
        currentPiece = (currentPiece == .white) ? .black : .white
        die1 = Int.random(in: 1...6)
        die2 = Int.random(in: 1...6)
    }
}

// MARK: - BoardRow

private struct BoardRow: View {
    let title: String
    let points: [Int]
    let slotWidth: CGFloat
    let spacing: CGFloat
    let board: BackgammonBoard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: spacing) {
                ForEach(points, id: \.self) { p in
                    PointSlot(
                        point: p,
                        slotWidth: slotWidth,
                        content: board.content(at: p)
                    )
                }
            }

            HStack(spacing: spacing) {
                ForEach(points, id: \.self) { p in
                    Text("\(p)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: slotWidth)
                }
            }
        }
    }
}

// MARK: - PointSlot

private struct PointSlot: View {
    struct Content {
        var white: Int
        var black: Int
    }

    let point: Int
    let slotWidth: CGFloat
    let content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: slotWidth, height: 44)

            if content.white == 0 && content.black == 0 {
                Text("–")
                    .font(.headline)
                    .foregroundColor(.secondary.opacity(0.7))
            } else if content.white > 0 && content.black == 0 {
                checkerBadge(count: content.white, piece: .white)
            } else if content.black > 0 && content.white == 0 {
                checkerBadge(count: content.black, piece: .black)
            } else {
                // caso raro (ambos en mismo punto): mostramos 2 badges
                VStack(spacing: 4) {
                    checkerBadge(count: content.black, piece: .black).scaleEffect(0.90)
                    checkerBadge(count: content.white, piece: .white).scaleEffect(0.90)
                }
            }
        }
    }

    private func checkerBadge(count: Int, piece: Piece) -> some View {
        let bg: Color = (piece == .white) ? .white : .black
        let fg: Color = (piece == .white) ? .black : .white

        return Text("\(count)")
            .font(.headline.bold())
            .foregroundColor(fg)
            .frame(width: 30, height: 30)
            .background(bg)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.black.opacity(piece == .white ? 0.18 : 0.05), lineWidth: 1)
            )
    }
}

// MARK: - Data model (simple)

private enum Piece {
    case white
    case black
}

private struct BackgammonBoard {
    private var white: [Int: Int] = [:]
    private var black: [Int: Int] = [:]

    static func standardSetup() -> BackgammonBoard {
        var b = BackgammonBoard()

        // ✅ Setup estándar real (por puntos 1...24)

        // BLANCAS: 24=2, 13=5, 8=3, 6=5
        b.white[24] = 2
        b.white[13] = 5
        b.white[8]  = 3
        b.white[6]  = 5

        // NEGRAS: 1=2, 12=5, 17=3, 19=5
        b.black[1]  = 2
        b.black[12] = 5
        b.black[17] = 3
        b.black[19] = 5

        return b
    }

    func content(at point: Int) -> PointSlot.Content {
        PointSlot.Content(
            white: white[point, default: 0],
            black: black[point, default: 0]
        )
    }
}
