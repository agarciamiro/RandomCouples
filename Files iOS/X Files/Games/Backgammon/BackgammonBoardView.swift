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
    @State private var dice: [Int] = []          // valores disponibles
    @State private var diceUsed: [Bool] = []     // consumidos (mismo tamaño que dice)

    // Tablero: 24 posiciones (1...24)
    @State private var points: [Int: BGPointStack]

    // ✅ BAR (fichas comidas) por COLOR REAL
    @State private var barWhite: Int = 0
    @State private var barBlack: Int = 0

    // ✅ MVP B1: selección + destinos posibles
    @State private var selectedFrom: Int? = nil
    @State private var highlightedTo: Set<Int> = []
    @State private var lastComputedMoves: [Int: Int] = [:] // destino -> dado usado (valor)

    // ✅ Turno perdido automático
    @State private var showTurnLostBanner: Bool = false
    @State private var autoSkippedThisTurn: Bool = false

    // MARK: - Inits (compatibles con tus llamadas)

    init(colors: BackgammonColorAssignment, startResult: BackgammonStartDiceResult) {
        self.colors = colors
        self.startResult = startResult

        // Si aún no pasamos nombres reales, usamos etiquetas claras
        self.casaName = "CASA (P1)"
        self.visitaName = "VISITA (P2)"

        let starter: BGPiece = startResult.starterIsBlack ? .black : .white

        _turnNumber = State(initialValue: 1)
        _current = State(initialValue: starter)

        // ✅ Set de dados inicial (2 dados; si dobles => 4 movimientos del mismo valor)
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

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {

            header

            Divider()

            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    // ✅ CLAVE: NO inflar el width (si se infla, el tablero "nace" más ancho y se esconde a la derecha)
                    boardGrid(availableWidth: geo.size.width)
                        .frame(minWidth: geo.size.width, alignment: .center) // centra y evita “corte” perceptible
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
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Cerrar")
            }
        }
        .onAppear {
            clearSelection()
            autoHandleTurnLostIfNeeded()
        }
        .onChange(of: current) { _, _ in
            autoHandleTurnLostIfNeeded()
        }
        .onChange(of: diceUsed) { _, _ in
            if remainingDiceValues.isEmpty { clearSelection() }
        }
        .onChange(of: barWhite) { _, _ in
            autoHandleTurnLostIfNeeded()
        }
        .onChange(of: barBlack) { _, _ in
            autoHandleTurnLostIfNeeded()
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
                    diceBox(diceText(index: 0))
                    Text("+")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                    diceBox(diceText(index: 1))
                }
            }
            .padding(.horizontal, 16)

            // ✅ Banner “Turno perdido” (automático)
            if showTurnLostBanner {
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

    private func nameForCurrent() -> String {
        let homeColor: BGPiece = (colors.blackSide == .player1) ? .black : .white
        return (current == homeColor) ? casaName : visitaName
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

    private func diceBox(_ text: String) -> some View {
        Text(text)
            .font(.title3.bold())
            .frame(width: 46, height: 46)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Board grid (2 filas x 12)

    private func boardGrid(availableWidth: CGFloat) -> some View {
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

                // ✅ BAR ARRIBA = VISITA
                barCell(width: barW, height: cellH, label: "VISITA")

                ForEach(topRight, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }
            }

            HStack(spacing: 6) {
                ForEach(botLeft, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }

                // ✅ BAR ABAJO = CASA
                barCell(width: barW, height: cellH, label: "CASA")

                ForEach(botRight, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }
            }
        }
    }

    private func barCell(width: CGFloat, height: CGFloat, label: String) -> some View {
        let homeColor: BGPiece = (colors.blackSide == .player1) ? .black : .white
        let ownerPiece: BGPiece = (label == "CASA") ? homeColor : (homeColor == .black ? .white : .black)
        let ownerCount: Int = (ownerPiece == .white) ? barWhite : barBlack
        let ownerLetter: String = (ownerPiece == .black) ? "N" : "B"   // N=Negras, B=Blancas

        let ownerIsCurrent = (current == ownerPiece)
        let selectable = ownerIsCurrent && ownerCount > 0 && !barHasNoLegalEntry

        return VStack(spacing: 2) {
            Rectangle()
                .fill(Color.gray.opacity(0.22))
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

            Text("\(ownerLetter)\(ownerCount)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 24)
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

    // MARK: - Actions (MVP B1 + BAR)

    private func handleTap(on index: Int) {
        if highlightedTo.contains(index),
           let from = selectedFrom,
           let usedDieValue = lastComputedMoves[index] {
            applyMove(from: from, to: index, usingDieValue: usedDieValue)
            return
        }

        if barHasPiecesForCurrent {
            clearSelection()
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

        let diceValues = remainingDiceValues
        guard !diceValues.isEmpty else { return }

        if index == Self.barSourceIndex {
            for v in diceValues {
                let entry = barEntryPoint(forDie: v)
                guard (1...24).contains(entry) else { continue }
                if isDestinationAllowed(to: entry) {
                    highlightedTo.insert(entry)
                    lastComputedMoves[entry] = v
                }
            }
            autoHandleTurnLostIfNeeded()
            return
        }

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
        return dest.count <= 1
    }

    private func applyMove(from: Int, to: Int, usingDieValue dieValue: Int) {
        consumeOneDie(value: dieValue)

        if from == Self.barSourceIndex {
            decrementBarForCurrent()
            applyArrival(to: to)
            postMoveSelection(nextFrom: to)
            return
        }

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
            if dst.count == 1 {
                incrementBarForPiece(dst.piece)
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
        // ✅ Turno perdido automático; el botón queda deshabilitado mientras muestra el banner
        if showTurnLostBanner { return false }

        // Normal: solo cuando consumiste todos los dados
        return remainingDiceValues.isEmpty
    }

    private var nextTurnButtonTitle: String {
        return canEndTurn ? "Continuar (Siguiente turno)" : "Usa tus dados"
    }

    private var boardHintText: String {
        if showTurnLostBanner {
            return "Turno perdido. Pasando al siguiente jugador…"
        }

        if barHasPiecesForCurrent {
            if barHasNoLegalEntry {
                return "BAR bloqueado. No hay jugadas legales."
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

        // Reset flags
        showTurnLostBanner = false
        autoSkippedThisTurn = false

        clearSelection()
        autoHandleTurnLostIfNeeded()
    }

    // MARK: - Dirección (Casa)

    private func moveDirectionForCurrent() -> Int {
        let homeColor: BGPiece = (colors.blackSide == .player1) ? .black : .white
        return (current == homeColor) ? -1 : 1
    }

    // MARK: - BAR logic (Turno perdido automático)

    private static let barSourceIndex: Int = 0

    private var barHasPiecesForCurrent: Bool {
        current == .white ? (barWhite > 0) : (barBlack > 0)
    }

    private func decrementBarForCurrent() {
        if current == .white {
            barWhite = max(0, barWhite - 1)
        } else {
            barBlack = max(0, barBlack - 1)
        }
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

    private func autoHandleTurnLostIfNeeded() {
        // ✅ Caso: hay fichas en BAR + dados presentes + NO hay entrada legal => TURNO PERDIDO AUTOMÁTICO
        guard barHasPiecesForCurrent else { return }
        guard barHasNoLegalEntry else { return }
        guard !autoSkippedThisTurn else { return }
        guard !showTurnLostBanner else { return }

        autoSkippedThisTurn = true
        showTurnLostBanner = true
        clearSelection()

        // Pequeño delay para que el usuario lo vea (sin tocar botón)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            self.nextTurn()
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
