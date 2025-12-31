import SwiftUI

struct BackgammonBoardView: View {

    // Inputs
    private let colors: BackgammonColorAssignment
    private let startResult: BackgammonStartDiceResult

    // ✅ Regla permanente: Player 1 = La Casa
    private let casaName: String
    private let visitaName: String

    @Environment(\.dismiss) private var dismiss

    // Turno
    @State private var turnNumber: Int
    @State private var current: BGPiece

    // ✅ Dados como “usos restantes” (dobles = 4 movimientos)
    @State private var remainingDice: [Int]

    // ✅ BAR (fichas comidas)
    @State private var barWhite: Int
    @State private var barBlack: Int

    // Tablero: 24 posiciones (1...24)
    @State private var points: [Int: BGPointStack]

    // ✅ MVP B1: selección + destinos posibles
    // selectedFrom: 1...24 para tablero, 0 = BAR del jugador actual
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

        // ✅ Dados iniciales: normalmente 2; si por algún motivo fueran dobles, serían 4
        let a = startResult.startMajor
        let b = startResult.startMinor
        if a == b {
            _remainingDice = State(initialValue: [a, a, a, a])
        } else {
            _remainingDice = State(initialValue: [a, b])
        }

        _barWhite = State(initialValue: 0)
        _barBlack = State(initialValue: 0)

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
        .navigationBarBackButtonHidden(true) // ✅ evita volver atrás por error
        .toolbar {
            // ✅ “Cerrar” discreto arriba a la derecha
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Cerrar juego")
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

                // ✅ Color + jugador (Casa / Visita)
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

                // ✅ DADOS (muestra 2 cajas: los 2 primeros “usos” restantes)
                HStack(spacing: 10) {
                    diceBox(displayDie(at: 0))
                    Text("+")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                    diceBox(displayDie(at: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // ✅ BAR: si el jugador actual tiene fichas comidas, debe salir primero
            if currentBarCount > 0 {
                Button {
                    // Selección desde BAR (origen 0)
                    selectedFrom = 0
                    computeHighlights(from: 0)
                } label: {
                    HStack(spacing: 10) {
                        Text("BAR")
                            .font(.footnote.bold())
                        Text("x\(currentBarCount)")
                            .font(.footnote.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground))
    }

    private func nameForCurrent() -> String {
        // ✅ Player 1 = Casa. El color de Casa lo define la ruleta.
        let homeColor: BGPiece = (colors.blackSide == .player1) ? .black : .white
        return (current == homeColor) ? casaName : visitaName
    }

    private func displayDie(at idx: Int) -> String {
        guard idx < remainingDice.count else { return "—" }
        return "\(remainingDice[idx])"
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

    // MARK: - Actions (MVP B1 + BAR + DOBLES)

    private func handleTap(on index: Int) {
        // Si tocó un destino válido (resaltado), ejecutamos movimiento
        if highlightedTo.contains(index), let from = selectedFrom, let usedDie = lastComputedMoves[index] {
            if from == 0 {
                applyMoveFromBar(to: index, using: usedDie)
            } else {
                applyMove(from: from, to: index, using: usedDie)
            }
            return
        }

        // Regla BAR: si tienes fichas en BAR, NO puedes seleccionar desde el tablero
        if currentBarCount > 0 {
            // Permitimos seleccionar BAR desde el botón BAR (header). Si toca tablero: ignoramos o limpiamos.
            clearSelection()
            return
        }

        // Si tocó un origen válido, seleccionamos y calculamos destinos
        if canSelectFrom(index: index) {
            selectedFrom = index
            computeHighlights(from: index)
            return
        }

        // Caso contrario: limpiar selección
        clearSelection()
    }

    private func canSelectFrom(index: Int) -> Bool {
        guard let stack = points[index], stack.count > 0, stack.piece != .none else { return false }
        return stack.piece == current
    }

    private func computeHighlights(from index: Int) {
        highlightedTo.removeAll()
        lastComputedMoves.removeAll()

        let dice = remainingDice
        guard !dice.isEmpty else { return }

        let dir = moveDirectionForCurrent()

        // ✅ Desde BAR (index == 0): el “origen” no es un punto, se re-ingresa en el home board del rival
        if index == 0 {
            for d in dice {
                let to: Int
                if dir == -1 {
                    // mueve 24→1 => entra por 24..19
                    to = 25 - d
                } else {
                    // mueve 1→24 => entra por 1..6
                    to = d
                }

                guard (1...24).contains(to) else { continue }
                if isDestinationAllowed(to: to) {
                    highlightedTo.insert(to)
                    lastComputedMoves[to] = d
                }
            }
            return
        }

        // ✅ Desde tablero normal
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

        // bloqueado si hay 2+ del rival
        return dest.count <= 1
    }

    private func applyMove(from: Int, to: Int, using dieUsed: Int) {
        guard var src = points[from], var dst = points[to] else { return }
        guard src.count > 0, src.piece == current else { return }

        // Consumir ficha en origen
        src.count -= 1
        if src.count == 0 { src.piece = .none }
        points[from] = src

        // Destino
        if dst.count == 0 || dst.piece == .none {
            dst.piece = current
            dst.count = 1
        } else if dst.piece == current {
            dst.count += 1
        } else {
            // ✅ CAPTURA REAL: si había 1 del rival -> lo mandamos al BAR
            if dst.count == 1 {
                addToBar(piece: opponent(of: current), count: 1)
                dst.piece = current
                dst.count = 1
            } else {
                // No debería pasar por isDestinationAllowed, pero por seguridad:
                return
            }
        }
        points[to] = dst

        consumeDie(dieUsed)

        // Recalcular highlights
        postMoveSelection(nextFocusPoint: to)
    }

    private func applyMoveFromBar(to: Int, using dieUsed: Int) {
        // Debe tener bar > 0
        guard currentBarCount > 0 else { return }
        guard var dst = points[to] else { return }

        // Destino (con captura)
        if dst.count == 0 || dst.piece == .none {
            dst.piece = current
            dst.count = 1
        } else if dst.piece == current {
            dst.count += 1
        } else {
            if dst.count == 1 {
                addToBar(piece: opponent(of: current), count: 1)
                dst.piece = current
                dst.count = 1
            } else {
                return
            }
        }
        points[to] = dst

        // Reducir BAR del actual
        addToBar(piece: current, count: -1)

        consumeDie(dieUsed)

        // Si aún quedan fichas en BAR, seguimos obligando a salir de BAR
        if currentBarCount > 0, !remainingDice.isEmpty {
            selectedFrom = 0
            computeHighlights(from: 0)
        } else {
            postMoveSelection(nextFocusPoint: to)
        }
    }

    private func consumeDie(_ dieUsed: Int) {
        // ✅ Quita 1 “uso” de ese dado (dobles funcionan solos)
        if let i = remainingDice.firstIndex(of: dieUsed) {
            remainingDice.remove(at: i)
        } else if !remainingDice.isEmpty {
            // fallback ultra seguro
            remainingDice.removeFirst()
        }
    }

    private func postMoveSelection(nextFocusPoint: Int) {
        if remainingDice.isEmpty {
            clearSelection()
            return
        }

        // Si aparece BAR (por captura previa), la regla obliga
        if currentBarCount > 0 {
            selectedFrom = 0
            computeHighlights(from: 0)
            return
        }

        // UX: mantenemos foco en la ficha movida
        selectedFrom = nextFocusPoint
        computeHighlights(from: nextFocusPoint)
    }

    private func clearSelection() {
        selectedFrom = nil
        highlightedTo.removeAll()
        lastComputedMoves.removeAll()
    }

    // MARK: - Turn management

    private var canEndTurn: Bool {
        // Turno termina cuando ya no quedan “usos” de dados
        return remainingDice.isEmpty
    }

    private var nextTurnButtonTitle: String {
        canEndTurn ? "Continuar (Siguiente turno)" : "Usa tus dados"
    }

    private var boardHintText: String {
        if canEndTurn {
            return "Dados consumidos. Puedes pasar al siguiente turno."
        }
        if currentBarCount > 0 {
            return "Tienes fichas en BAR. Debes sacarlas primero."
        }
        if selectedFrom == nil {
            return "Toca una casilla con tus fichas para ver destinos posibles."
        }
        return "Elige un destino resaltado en verde."
    }

    private func nextTurn() {
        turnNumber += 1
        current = (current == .white) ? .black : .white

        let d1 = Int.random(in: 1...6)
        let d2 = Int.random(in: 1...6)
        if d1 == d2 {
            remainingDice = [d1, d1, d1, d1]
        } else {
            remainingDice = [d1, d2]
        }

        clearSelection()

        // Si el nuevo jugador tiene BAR, lo forzamos inmediatamente
        if currentBarCount > 0 {
            selectedFrom = 0
            computeHighlights(from: 0)
        }
    }

    // MARK: - Dirección (Casa)

    private func moveDirectionForCurrent() -> Int {
        // ✅ Regla: La Casa (P1) va 24 → 1, y es del color asignado por la ruleta.
        let homeColor: BGPiece = (colors.blackSide == .player1) ? .black : .white
        return (current == homeColor) ? -1 : 1
    }

    // MARK: - BAR helpers

    private var currentBarCount: Int {
        barCount(for: current)
    }

    private func barCount(for piece: BGPiece) -> Int {
        switch piece {
        case .white: return barWhite
        case .black: return barBlack
        case .none:  return 0
        }
    }

    private func addToBar(piece: BGPiece, count: Int) {
        switch piece {
        case .white:
            barWhite = max(0, barWhite + count)
        case .black:
            barBlack = max(0, barBlack + count)
        case .none:
            break
        }
    }

    private func opponent(of piece: BGPiece) -> BGPiece {
        piece == .white ? .black : .white
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
