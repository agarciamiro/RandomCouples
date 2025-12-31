import SwiftUI

struct BackgammonBoardView: View {

    // Inputs
    private let colors: BackgammonColorAssignment
    private let startResult: BackgammonStartDiceResult

    // ✅ Regla permanente: Player 1 = La Casa
    private let casaName: String
    private let visitaName: String

    @Environment(\.dismiss) private var dismiss

    // Turno / dados
    @State private var turnNumber: Int
    @State private var current: BGPiece
    @State private var die1: Int
    @State private var die2: Int

    // Tablero: 24 posiciones (1...24)
    @State private var points: [Int: BGPointStack]

    // ✅ MVP B1: selección + destinos posibles
    @State private var selectedFrom: Int? = nil
    @State private var highlightedTo: Set<Int> = []
    @State private var lastComputedMoves: [Int: Int] = [:] // destino -> dado usado

    // MARK: - Inits (compatibles con tus llamadas)

    init(colors: BackgammonColorAssignment, startResult: BackgammonStartDiceResult) {
        self.colors = colors
        self.startResult = startResult

        // ✅ Player 1 = Casa (si aún no pasamos nombres reales, usamos etiquetas claras)
        self.casaName = "CASA (P1)"
        self.visitaName = "VISITA (P2)"

        let starter: BGPiece = startResult.starterIsBlack ? .black : .white

        _turnNumber = State(initialValue: 1)
        _current = State(initialValue: starter)
        _die1 = State(initialValue: startResult.startMajor)
        _die2 = State(initialValue: startResult.startMinor)

        // ✅ Setup RELATIVO a Casa (abajo siempre 24/13/8/6)
        let homeColor: BGPiece = (colors.blackSide == .player1) ? .black : .white
        _points = State(initialValue: Self.standardSetup(homeColor: homeColor))
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

            Text(boardHintText)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                nextTurn()
            } label: {
                Text(nextTurnButtonTitle)
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
            .disabled(!canEndTurn)
        }
        .navigationTitle("Tablero")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cerrar") { dismiss() }
            }
        }
        .onAppear {
            clearSelection()
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

                // ✅ Color + jugador (Casa / Visita) para no confundir
                VStack(spacing: 2) {
                    Text(current == .white ? "BLANCAS" : "NEGRAS")
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())

                    Text(nameForCurrent())
                        .font(.footnote.bold())
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 10) {
                    diceBox(die1 == 0 ? "—" : "\(die1)")
                    Text("+")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                    diceBox(die2 == 0 ? "—" : "\(die2)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(Color(.systemBackground))
    }

    private func nameForCurrent() -> String {
        // ✅ Player 1 = Casa. El color de Casa lo define la ruleta.
        let homeColor: BGPiece = (colors.blackSide == .player1) ? .black : .white
        return (current == homeColor) ? casaName : visitaName
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
        let spacing: CGFloat = 6
        let hPad: CGFloat = 32
        let usable = max(0, availableWidth - hPad)
        let cellH: CGFloat = 50
        let cellW: CGFloat = max(18, floor((usable - barW - (spacing * 12)) / 12))

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

        let isSelected = (selectedFrom == index)
        let isHighlighted = highlightedTo.contains(index)

        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(borderColor(isSelected: isSelected, isHighlighted: isHighlighted),
                                    lineWidth: (isSelected || isHighlighted) ? 3 : 0)
                    )

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
        .contentShape(Rectangle())
        .onTapGesture { handleTap(on: index) }
    }

    private func borderColor(isSelected: Bool, isHighlighted: Bool) -> Color {
        if isSelected { return Color.blue }
        if isHighlighted { return Color.green }
        return Color.clear
    }

    // MARK: - Actions (MVP B1)

    private func handleTap(on index: Int) {
        if highlightedTo.contains(index), let from = selectedFrom, let usedDie = lastComputedMoves[index] {
            applyMove(from: from, to: index, using: usedDie)
            return
        }

        if canSelectFrom(index: index) {
            selectedFrom = index
            computeHighlights(from: index)
            return
        }

        clearSelection()
    }

    private func canSelectFrom(index: Int) -> Bool {
        guard let stack = points[index], stack.count > 0, stack.piece != .none else { return false }
        return stack.piece == current
    }

    private func computeHighlights(from index: Int) {
        highlightedTo.removeAll()
        lastComputedMoves.removeAll()

        let dice = availableDice
        guard !dice.isEmpty else { return }

        let dir = moveDirectionForCurrent()

        for d in dice {
            let to = index + (dir * d)
            guard (1...24).contains(to) else { continue }
            if isDestinationAllowed(to: to) {
                highlightedTo.insert(to)
                lastComputedMoves[to] = d
            }
        }
    }

    private func isDestinationAllowed(to: Int) -> Bool {
        guard let dest = points[to] else { return true }
        if dest.count == 0 || dest.piece == .none { return true }
        if dest.piece == current { return true }
        return dest.count <= 1
    }

    private func applyMove(from: Int, to: Int, using dieUsed: Int) {
        guard var src = points[from], var dst = points[to] else { return }
        guard src.count > 0, src.piece == current else { return }

        src.count -= 1
        if src.count == 0 { src.piece = .none }
        points[from] = src

        if dst.count == 0 || dst.piece == .none {
            dst.piece = current
            dst.count = 1
        } else if dst.piece == current {
            dst.count += 1
        } else {
            dst.piece = current
            dst.count = 1
        }
        points[to] = dst

        if die1 == dieUsed {
            die1 = 0
        } else if die2 == dieUsed {
            die2 = 0
        } else {
            if die1 != 0 { die1 = 0 } else { die2 = 0 }
        }

        if availableDice.isEmpty {
            clearSelection()
        } else {
            selectedFrom = to
            computeHighlights(from: to)
        }
    }

    private func clearSelection() {
        selectedFrom = nil
        highlightedTo.removeAll()
        lastComputedMoves.removeAll()
    }

    // MARK: - Turn management

    private var availableDice: [Int] {
        [die1, die2].filter { $0 > 0 }
    }

    private var canEndTurn: Bool {
        die1 == 0 && die2 == 0
    }

    private var nextTurnButtonTitle: String {
        canEndTurn ? "Continuar (Siguiente turno)" : "Usa tus dados"
    }

    private var boardHintText: String {
        if canEndTurn { return "Dados consumidos. Puedes pasar al siguiente turno." }
        if selectedFrom == nil { return "Toca una casilla con tus fichas para ver destinos posibles." }
        return "Elige un destino resaltado en verde."
    }

    private func nextTurn() {
        turnNumber += 1
        current = (current == .white) ? .black : .white
        die1 = Int.random(in: 1...6)
        die2 = Int.random(in: 1...6)
        clearSelection()
    }

    // MARK: - Dirección (Casa)

    private func moveDirectionForCurrent() -> Int {
        // ✅ Regla: La Casa (P1) va 24 → 1, y es del color asignado por la ruleta.
        let homeColor: BGPiece = (colors.blackSide == .player1) ? .black : .white
        return (current == homeColor) ? -1 : 1
    }

    // MARK: - Standard setup (RELATIVO A CASA)

    private static func standardSetup(homeColor: BGPiece) -> [Int: BGPointStack] {
        var p: [Int: BGPointStack] = [:]
        for i in 1...24 { p[i] = BGPointStack(piece: .none, count: 0) }

        let awayColor: BGPiece = (homeColor == .black) ? .white : .black

        // Casa (abajo): 2 en 24, 5 en 13, 3 en 8, 5 en 6
        p[24] = BGPointStack(piece: homeColor, count: 2)
        p[13] = BGPointStack(piece: homeColor, count: 5)
        p[8]  = BGPointStack(piece: homeColor, count: 3)
        p[6]  = BGPointStack(piece: homeColor, count: 5)

        // Visita (arriba): 2 en 1, 5 en 12, 3 en 17, 5 en 19
        p[1]  = BGPointStack(piece: awayColor, count: 2)
        p[12] = BGPointStack(piece: awayColor, count: 5)
        p[17] = BGPointStack(piece: awayColor, count: 3)
        p[19] = BGPointStack(piece: awayColor, count: 5)

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
