import SwiftUI

struct BackgammonBoardView: View {

    // Inputs
    private let colors: BackgammonColorAssignment
    private let startResult: BackgammonStartDiceResult

    @Environment(\.dismiss) private var dismiss

    // Turno / dados
    @State private var turnNumber: Int
    @State private var current: BGPiece
    @State private var die1: Int
    @State private var die2: Int

    // Tablero: 24 posiciones (1...24)
    @State private var points: [Int: BGPointStack]

    // MARK: - Inits (compatibles con tus llamadas)

    init(colors: BackgammonColorAssignment, startResult: BackgammonStartDiceResult) {
        self.colors = colors
        self.startResult = startResult

        let starter: BGPiece = startResult.starterIsBlack ? .black : .white

        _turnNumber = State(initialValue: 1)
        _current = State(initialValue: starter)
        _die1 = State(initialValue: startResult.startMajor)
        _die2 = State(initialValue: startResult.startMinor)
        _points = State(initialValue: Self.standardSetup())
    }

    init(startResult: BackgammonStartDiceResult, colors: BackgammonColorAssignment) {
        self.init(colors: colors, startResult: startResult)
    }

    init(colors: BackgammonColorAssignment, result: BackgammonStartDiceResult) {
        self.init(colors: colors, startResult: result)
    }

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {

            header

            Divider()

            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    boardGrid(availableWidth: geo.size.width)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
            }

            Text("Setup estándar cargado (sin movimientos aún).")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                nextTurn()
            } label: {
                Text("Continuar (Siguiente turno)")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Tablero")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cerrar") { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("TABLERO (24 posiciones)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Turno \(turnNumber)")
                        .font(.title3.bold())

                    Text("Juega:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(current == .white ? "BLANCAS" : "NEGRAS")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())

                HStack(spacing: 10) {
                    diceBox("\(die1)")
                    Text("+")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                    diceBox("\(die2)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(Color(.systemBackground))
    }

    private func diceBox(_ text: String) -> some View {
        Text(text)
            .font(.title3.bold())
            .frame(width: 46, height: 46)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Board grid (2 filas x 12)

    private func boardGrid(availableWidth: CGFloat) -> some View {
        // Clockwise order + bar between 18/19 and 6/7
        let barW: CGFloat = 12
        let cellH: CGFloat = 50
        let cellW: CGFloat = max(18, floor((availableWidth - barW - 24) / 12))

        let topLeft  = [13,14,15,16,17,18]
        let topRight = [19,20,21,22,23,24]
        let botLeft  = [12,11,10,9,8,7]
        let botRight = [6,5,4,3,2,1]

        return VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(topLeft, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.22))
                    .frame(width: barW, height: cellH)
                    .cornerRadius(8)

                ForEach(topRight, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }
            }

            HStack(spacing: 6) {
                ForEach(botLeft, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.22))
                    .frame(width: barW, height: cellH)
                    .cornerRadius(8)

                ForEach(botRight, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }
            }
        }
    }

    private func pointCell(index: Int, cellW: CGFloat, cellH: CGFloat) -> some View {
        let stack = points[index] ?? BGPointStack(piece: .none, count: 0)
        let dot = min(cellW, cellH) * 0.62

        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))

                if stack.count == 0 || stack.piece == .none {
                    Text("–")
                        .font(.system(size: max(12, dot * 0.6), weight: .bold))
                        .foregroundColor(.secondary)
                } else {
                    ZStack {
                        Circle()
                            .fill(stack.piece == .black ? Color(.label) : Color(.systemBackground))
                            .overlay(Circle().stroke(Color(.separator), lineWidth: 1))

                        Text("\(stack.count)")
                            .font(.system(size: max(10, dot * 0.45), weight: .bold))
                            .foregroundColor(stack.piece == .black ? .white : .black)
                    }
                    .frame(width: dot, height: dot)
                }
            }

            Text("\(index)")
                .font(.system(size: max(9, dot * 0.22)))
                .foregroundColor(.secondary)
        }
        .frame(width: cellW, height: cellH)
    }

    // MARK: - Actions

    private func nextTurn() {
        turnNumber += 1
        current = (current == .white) ? .black : .white
        die1 = Int.random(in: 1...6)
        die2 = Int.random(in: 1...6)
    }

    // MARK: - Standard setup (Backgammon clásico)

    private static func standardSetup() -> [Int: BGPointStack] {
        var p: [Int: BGPointStack] = [:]
        for i in 1...24 { p[i] = BGPointStack(piece: .none, count: 0) }

        // Blancas (white): 2 en 24, 5 en 13, 3 en 8, 5 en 6
        p[24] = BGPointStack(piece: .black, count: 2)
        p[13] = BGPointStack(piece: .black, count: 5)
        p[8]  = BGPointStack(piece: .black, count: 3)
        p[6]  = BGPointStack(piece: .black, count: 5)

        // Negras (black): 2 en 1, 5 en 12, 3 en 17, 5 en 19
        p[1]  = BGPointStack(piece: .white, count: 2)
        p[12] = BGPointStack(piece: .white, count: 5)
        p[17] = BGPointStack(piece: .white, count: 3)
        p[19] = BGPointStack(piece: .white, count: 5)

        return p
    }
}

// MARK: - Helpers locales (evita conflictos con otros nombres del proyecto)

private enum BGPiece {
    case none
    case white
    case black
}

private struct BGPointStack {
    var piece: BGPiece
    var count: Int
}
