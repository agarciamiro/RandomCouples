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

    // ✅ Dados “consumibles” (soporta dobles = 4 movimientos)
    @State private var dice: [Int] = []
    @State private var diceUsed: [Bool] = []

    // Tablero: 24 posiciones (1...24)
    @State private var points: [Int: BGPointStack]

    // ✅ BAR por COLOR REAL capturado (blancas vs negras)
    @State private var barWhite: Int = 0
    @State private var barBlack: Int = 0

    // ✅ MVP B1: selección + destinos posibles
    @State private var selectedFrom: Int? = nil
    @State private var highlightedTo: Set<Int> = []
    @State private var lastComputedMoves: [Int: Int] = [:] // destino -> dado usado (valor)

    // MARK: - Inits (compatibles con tus llamadas)

    init(colors: BackgammonColorAssignment, startResult: BackgammonStartDiceResult) {
        self.colors = colors
        self.startResult = startResult

        self.casaName = "CASA (P1)"
        self.visitaName = "VISITA (P2)"

        let starter: BGPiece = startResult.starterIsBlack ? .black : .white
        _turnNumber = State(initialValue: 1)
        _current = State(initialValue: starter)

        // ✅ Dados iniciales (apertura)
        let d1 = startResult.startMajor
        let d2 = startResult.startMinor
        if d1 == d2 {
            _dice = State(initialValue: [d1, d1, d1, d1])
            _diceUsed = State(initialValue: [false, false, false, false])
        } else {
            _dice = State(initialValue: [d1, d2])
            _diceUsed = State(initialValue: [false, false])
        }

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

    // MARK: - CASA / VISITA mapping (clave para BAR)

    private var casaPiece: BGPiece {
        (colors.blackSide == .player1) ? .black : .white
    }

    private var visitaPiece: BGPiece {
        (casaPiece == .black) ? .white : .black
    }

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {

            header

            Divider()

            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    boardGrid(availableWidth: geo.size.width)
                        .frame(minWidth: geo.size.width, alignment: .center) // ✅ clave: centra y evita “corte” a la derecha
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .padding(8)
                        .background(Color(.systemGray4))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Cerrar")
            }
        }
        .onAppear {
            clearSelection()
            // Si hay BAR bloqueado, no “auto-salta”: solo mostramos el estado y habilitamos continuar
            if barHasPiecesForCurrent && barHasNoLegalEntry {
                clearSelection()
            }
        }
        .onChange(of: current) { _, _ in
            if barHasPiecesForCurrent && barHasNoLegalEntry {
                clearSelection()
            }
        }
        .onChange(of: diceUsed) { _, _ in
            if remainingDiceValues.isEmpty { clearSelection() }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("TABLERO (24 posiciones)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            // ✅ Layout: izquierda info, centro dados + dirección, derecha jugador
            HStack(alignment: .center, spacing: 14) {

                // IZQUIERDA
                VStack(alignment: .leading, spacing: 4) {
                    Text("Turno \(turnNumber)")
                        .font(.title3.bold())

                    Text("Juega:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)

                // CENTRO (DADOS + DIRECCIÓN)
                VStack(spacing: 6) {
                    HStack(spacing: 10) {
                        diceBox(diceText(index: 0))
                        Text("+")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                        diceBox(diceText(index: 1))
                    }

                    // ✅ Indicador visual de dirección (C)
                    Text(directionIndicatorText)
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)

                // DERECHA (JUGADOR)
                VStack(spacing: 2) {
                    Text(current == .white ? "BLANCAS" : "NEGRAS")
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray4))
                        .clipShape(Capsule())

                    Text(nameForCurrent())
                        .font(.footnote.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)

            // ✅ Banner persistente: TURNO PERDIDO (hasta que el usuario toque continuar)
            if barHasPiecesForCurrent && barHasNoLegalEntry {
                Text("Turno perdido — BAR bloqueado (no hay jugadas legales).")
                    .font(.footnote.bold())
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.20))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            } else {
                Spacer(minLength: 8)
            }
        }
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
    }

    private var directionIndicatorText: String {
        if current == casaPiece {
            return "⬅️ CASA: 24 → 1"
        } else {
            return "VISITA: 1 → 24 ➡️"
        }
    }

    private func nameForCurrent() -> String {
        return (current == casaPiece) ? casaName : visitaName
    }

    private func diceText(index: Int) -> String {
        if index >= 2 { return "—" }
        if remainingDiceValues.isEmpty { return "—" }

        let visible: [Int]
        if dice.count == 4 { visible = [dice[0], dice[0]] }
        else { visible = dice }

        if index >= visible.count { return "—" }

        let v = visible[index]
        let anyLeft = hasAnyDieLeft(with: v)
        return anyLeft ? "\(v)" : "—"
    }

    // ✅ Dados ligeramente grises para mejor contraste
    private func diceBox(_ text: String) -> some View {
        Text(text)
            .font(.title3.bold())
            .frame(width: 46, height: 46)
            .background(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundColor(.primary)
    }

    // MARK: - Board grid (2 filas x 12)

    private enum BarSlot { case topVisita, bottomCasa }

    private func boardGrid(availableWidth: CGFloat) -> some View {
        let barW: CGFloat = 34
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

            HStack(spacing: spacing) {
                ForEach(topLeft, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }

                // ✅ BAR SUPERIOR = VISITA (y muestra su color real con B/N)
                barCell(slot: .topVisita, width: barW, height: cellH)

                ForEach(topRight, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }
            }

            HStack(spacing: spacing) {
                ForEach(botLeft, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }

                // ✅ BAR INFERIOR = CASA (y muestra su color real con B/N)
                barCell(slot: .bottomCasa, width: barW, height: cellH)

                ForEach(botRight, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }
            }
        }
    }

    private func barCount(for piece: BGPiece) -> Int {
        switch piece {
        case .white: return barWhite
        case .black: return barBlack
        case .none: return 0
        }
    }

    private func barCell(slot: BarSlot, width: CGFloat, height: CGFloat) -> some View {
        let ownerPiece: BGPiece = (slot == .bottomCasa) ? casaPiece : visitaPiece
        let label: String = (slot == .bottomCasa) ? "CASA" : "VISITA"
        let count = barCount(for: ownerPiece)

        // ✅ Letra correcta: B=Blancas, N=Negras (según el “dueño” del BAR)
        let ownerLetter: String = (ownerPiece == .black) ? "N" : "B"

        // ✅ Solo es “seleccionable” si:
        // 1) es el BAR del jugador actual (current == ownerPiece)
        // 2) hay fichas ahí
        // 3) existe al menos una entrada legal
        let selectable = (current == ownerPiece) && (count > 0) && !barHasNoLegalEntry

        return VStack(spacing: 2) {
            Rectangle()
                .fill(Color.gray.opacity(0.30))
                .frame(width: width, height: height)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectable ? Color.blue : Color.clear, lineWidth: selectable ? 2 : 0)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    guard selectable else { return }
                    selectedFrom = Self.barSourceIndex
                    computeHighlights(from: Self.barSourceIndex)
                }

            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)

                Text("\(ownerLetter)\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 34)
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
                    .fill(Color(.systemGray5))
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

    // MARK: - Actions (MVP B1 + BAR)

    private func handleTap(on index: Int) {
        // ✅ Si tocó un destino válido, ejecutamos movimiento
        if highlightedTo.contains(index),
           let from = selectedFrom,
           let usedDieValue = lastComputedMoves[index] {
            applyMove(from: from, to: index, usingDieValue: usedDieValue)
            return
        }

        // ✅ Si hay BAR del jugador actual, no se puede seleccionar otra cosa
        if barHasPiecesForCurrent {
            clearSelection()
            return
        }

        // ✅ Selección normal en tablero
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

        let diceValues = remainingDiceValues
        guard !diceValues.isEmpty else { return }

        // ✅ Caso BAR
        if index == Self.barSourceIndex {
            for v in diceValues {
                let entry = barEntryPoint(forDie: v)
                guard (1...24).contains(entry) else { continue }
                if isDestinationAllowed(to: entry) {
                    highlightedTo.insert(entry)
                    lastComputedMoves[entry] = v
                }
            }
            return
        }

        // ✅ Caso normal
        let dir = moveDirectionForCurrent()
        for v in diceValues {
            let to = index + (dir * v)
            guard (1...24).contains(to) else { continue }
            if isDestinationAllowed(to: to) {
                highlightedTo.insert(to)
                lastComputedMoves[to] = v
            }
        }
    }

    private func isDestinationAllowed(to: Int) -> Bool {
        guard let dest = points[to] else { return true }
        if dest.count == 0 || dest.piece == .none { return true }
        if dest.piece == current { return true }
        // Bloqueado si hay 2+ del rival
        return dest.count <= 1
    }

    private func applyMove(from: Int, to: Int, usingDieValue dieValue: Int) {
        consumeOneDie(value: dieValue)

        // ✅ Mover desde BAR
        if from == Self.barSourceIndex {
            decrementBarForCurrent()
            applyArrival(to: to)
            postMoveSelection(nextFrom: to)
            return
        }

        // ✅ Mover desde tablero
        guard var src = points[from], var dst = points[to] else { return }
        guard src.count > 0, src.piece == current else { return }

        src.count -= 1
        if src.count == 0 { src.piece = .none }
        points[from] = src

        // Llegada
        if dst.count == 0 || dst.piece == .none {
            dst.piece = current
            dst.count = 1
        } else if dst.piece == current {
            dst.count += 1
        } else {
            if dst.count == 1 {
                incrementBarForPiece(dst.piece) // capturado va al BAR por su COLOR real
                dst.piece = current
                dst.count = 1
            }
        }
        points[to] = dst

        postMoveSelection(nextFrom: to)
    }

    private func applyArrival(to: Int) {
        guard var dst = points[to] else { return }

        if dst.count == 0 || dst.piece == .none {
            dst.piece = current
            dst.count = 1
        } else if dst.piece == current {
            dst.count += 1
        } else {
            if dst.count == 1 {
                incrementBarForPiece(dst.piece)
                dst.piece = current
                dst.count = 1
            }
        }
        points[to] = dst
    }

    private func postMoveSelection(nextFrom: Int) {
        // Si aún hay BAR del jugador actual, forzar selección en BAR
        if barHasPiecesForCurrent {
            selectedFrom = Self.barSourceIndex
            computeHighlights(from: Self.barSourceIndex)
            return
        }

        if remainingDiceValues.isEmpty {
            clearSelection()
        } else {
            selectedFrom = nextFrom
            computeHighlights(from: nextFrom)
        }
    }

    private func clearSelection() {
        selectedFrom = nil
        highlightedTo.removeAll()
        lastComputedMoves.removeAll()
    }

    // MARK: - Dice helpers (dobles=4)

    private var remainingDiceValues: [Int] {
        var out: [Int] = []
        for i in dice.indices {
            if i < diceUsed.count, diceUsed[i] == false {
                out.append(dice[i])
            }
        }
        return out
    }

    private func hasAnyDieLeft(with value: Int) -> Bool {
        for i in dice.indices {
            if i < diceUsed.count, diceUsed[i] == false, dice[i] == value {
                return true
            }
        }
        return false
    }

    private func consumeOneDie(value: Int) {
        for i in dice.indices {
            if i < diceUsed.count, diceUsed[i] == false, dice[i] == value {
                diceUsed[i] = true
                return
            }
        }
    }

    // MARK: - Turn management

    private var canEndTurn: Bool {
        // ✅ Si BAR está bloqueado: se permite terminar turno aunque queden dados
        if barHasPiecesForCurrent && barHasNoLegalEntry { return true }
        return remainingDiceValues.isEmpty
    }

    private var nextTurnButtonTitle: String {
        if barHasPiecesForCurrent && barHasNoLegalEntry {
            return "Continuar (Turno perdido)"
        }
        return canEndTurn ? "Continuar (Siguiente turno)" : "Usa tus dados"
    }

    private var boardHintText: String {
        if barHasPiecesForCurrent {
            if barHasNoLegalEntry {
                return "BAR bloqueado. No hay jugadas legales. Turno perdido."
            }
            return "Tienes ficha(s) en BAR. Debes salir del BAR primero."
        }
        if canEndTurn {
            return "Dados consumidos. Puedes pasar al siguiente turno."
        }
        if selectedFrom == nil {
            return "Toca una casilla con tus fichas para ver destinos posibles."
        }
        return "Elige un destino resaltado en verde."
    }

    private func nextTurn() {
        turnNumber += 1
        current = (current == .white) ? .black : .white

        // Nuevos dados
        let d1 = Int.random(in: 1...6)
        let d2 = Int.random(in: 1...6)
        if d1 == d2 {
            dice = [d1, d1, d1, d1]
            diceUsed = [false, false, false, false]
        } else {
            dice = [d1, d2]
            diceUsed = [false, false]
        }

        clearSelection()

        // Si el nuevo jugador entra con BAR bloqueado, banner queda fijo (no auto-skip)
        if barHasPiecesForCurrent && barHasNoLegalEntry {
            clearSelection()
        }
    }

    // MARK: - Dirección (Casa)

    private func moveDirectionForCurrent() -> Int {
        // ✅ La Casa va 24 → 1; Visita va 1 → 24
        return (current == casaPiece) ? -1 : 1
    }

    // MARK: - BAR logic

    private static let barSourceIndex: Int = 0

    private var barHasPiecesForCurrent: Bool {
        barCount(for: current) > 0
    }

    private func decrementBarForCurrent() {
        if current == .white { barWhite = max(0, barWhite - 1) }
        if current == .black { barBlack = max(0, barBlack - 1) }
    }

    private func incrementBarForPiece(_ piece: BGPiece) {
        if piece == .white { barWhite += 1 }
        if piece == .black { barBlack += 1 }
    }

    private var barHasNoLegalEntry: Bool {
        guard barHasPiecesForCurrent else { return false }
        let diceValues = remainingDiceValues
        guard !diceValues.isEmpty else { return false }

        for v in diceValues {
            let entry = barEntryPoint(forDie: v)
            if (1...24).contains(entry), isDestinationAllowed(to: entry) {
                return false
            }
        }
        return true
    }

    private func barEntryPoint(forDie dieValue: Int) -> Int {
        let dir = moveDirectionForCurrent()
        if dir == -1 {
            return 25 - dieValue
        } else {
            return dieValue
        }
    }

    // MARK: - Setup (RELATIVO A CASA)

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

// MARK: - Helpers locales

private enum BGPiece {
    case none
    case white
    case black
}

private struct BGPointStack {
    var piece: BGPiece
    var count: Int
}
