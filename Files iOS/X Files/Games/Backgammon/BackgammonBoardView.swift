import SwiftUI

struct BackgammonBoardView: View {

    // Modelos “UI” que ahora ya existen en BackgammonModels.swift
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

            // Banner arriba (no “se sale”)
            header

            Divider()

            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    boardGrid(availableWidth: geo.size.width)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
            }

            // Mensaje
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
                    Text("+").font(.title3.bold()).foregroundColor(.secondary)
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
        // 12 columnas; si no entra, el ScrollView horizontal lo resuelve.
        let cellW: CGFloat = 60
        let cellH: CGFloat = 54
        let spacing: CGFloat = 10

        return VStack(spacing: 16) {
            // Arriba: 24 → 13
            HStack(spacing: spacing) {
                ForEach(Array(stride(from: 24, through: 13, by: -1)), id: \.self) { idx in
                    pointCell(index: idx)
                        .frame(width: cellW, height: cellH)
                }
            }

            // Abajo: 12 → 1
            HStack(spacing: spacing) {
                ForEach(Array(stride(from: 12, through: 1, by: -1)), id: \.self) { idx in
                    pointCell(index: idx)
                        .frame(width: cellW, height: cellH)
                }
            }
        }
    }

    private func pointCell(index: Int) -> some View {
        let stack = points[index] ?? BGPointStack(piece: .none, count: 0)

        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))

                if stack.count == 0 || stack.piece == .none {
                    Text("–")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                } else {
                    ZStack {
                        Circle()
                            .fill(stack.piece == .black ? Color(.label) : Color(.systemBackground))
                            .overlay(
                                Circle().stroke(Color(.separator), lineWidth: 1)
                            )

                        Text("\(stack.count)")
                            .font(.headline.bold())
                            .foregroundColor(stack.piece == .black ? .white : .black)
                    }
                    .frame(width: 34, height: 34)
                }
            }

            Text("\(index)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
        p[24] = BGPointStack(piece: .white, count: 2)
        p[13] = BGPointStack(piece: .white, count: 5)
        p[8]  = BGPointStack(piece: .white, count: 3)
        p[6]  = BGPointStack(piece: .white, count: 5)

        // Negras (black): 2 en 1, 5 en 12, 3 en 17, 5 en 19
        p[1]  = BGPointStack(piece: .black, count: 2)
        p[12] = BGPointStack(piece: .black, count: 5)
        p[17] = BGPointStack(piece: .black, count: 3)
        p[19] = BGPointStack(piece: .black, count: 5)

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
