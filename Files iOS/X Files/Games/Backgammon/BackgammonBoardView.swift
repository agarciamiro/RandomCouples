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
                    ZStack {
                        boardGrid(availableWidth: geo.size.width)
                            .frame(minWidth: geo.size.width, alignment: .center) // ✅ clave: centra y evita “corte” a la derecha
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .opacity(barHasPiecesForCurrent ? 0.88 : 1.0)

                        // ✅ Overlay claro (NO bloquea el BAR)
                        if barHasPiecesForCurrent {
                            barOverlayHint
                                .padding(.horizontal, 24)
                                .allowsHitTesting(false)
                        }
                    }
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
                        dieBox(value: dieValueForUI(index: 0))
                        Text("+")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                        dieBox(value: dieValueForUI(index: 1))
                    }

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

            // ✅ Feedback cuando hay BAR (si no está bloqueado)
            if barHasPiecesForCurrent && !barHasNoLegalEntry {
                Text("Debes salir del BAR primero.")
                    .font(.footnote.bold())
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.12))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            }

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

    private var barOverlayHint: some View {
        let whereText = (current == casaPiece) ? "abajo" : "arriba"
        if barHasNoLegalEntry {
            return VStack(spacing: 10) {
                Text("BAR bloqueado")
                    .font(.headline.bold())
                Text("No hay entradas legales.\nTurno perdido: toca **Continuar**.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .frame(maxWidth: 320)
            .background(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.55), lineWidth: 2))
            .cornerRadius(14)
        } else {
            return VStack(spacing: 10) {
                Text("BAR obligatorio")
                    .font(.headline.bold())
                Text("Toca el **BAR \(whereText)** para entrar al tablero.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .frame(maxWidth: 320)
            .background(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.55), lineWidth: 2))
            .cornerRadius(14)
        }
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

    // MARK: - Dados (UI con pips, Opción B)

    private func dieValueForUI(index: Int) -> Int? {
        // Si no hay dados disponibles, mostrar vacío
        guard !remainingDiceValues.isEmpty else { return nil }
        guard index < 2 else { return nil }

        // Si son dobles (4), mostramos 2 dados iguales (visual)
        let visible: [Int] = (dice.count == 4) ? [dice[0], dice[0]] : dice
        guard index < visible.count else { return nil }

        let v = visible[index]
        return hasAnyDieLeft(with: v) ? v : nil
    }

    private func dieBox(value: Int?) -> some View {
        DieView(value: value, themeIsBlack: (current == .black))
            .frame(width: 46, height: 46)
            .accessibilityLabel(value == nil ? "Dado vacío" : "Dado \(value!)")
    }

    private struct DieView: View {
        let value: Int?
        let themeIsBlack: Bool

        var body: some View {
            // Opción B: dado “tema” según turno
            let fill: Color = themeIsBlack ? Color(.systemGray2) : Color(.systemGray6)
            let stroke: Color = Color(.systemGray4)
            let pip: Color = themeIsBlack ? .white : .black

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(stroke, lineWidth: 1)
                    )

                if let v = value, (1...6).contains(v) {
                    pipGrid(value: v, pipColor: pip)
                        .padding(7)
                } else {
                    Text("—")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                }
            }
        }

        private func pipDot(_ on: Bool, _ color: Color) -> some View {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .opacity(on ? 1.0 : 0.0)
        }

        private func pipGrid(value: Int, pipColor: Color) -> some View {
            // 3x3: TL, TC, TR / ML, MC, MR / BL, BC, BR
            let tl = (value == 2 || value == 3 || value == 4 || value == 5 || value == 6)
            let tr = tl
            let bl = tl
            let br = tl

            let mc = (value == 1 || value == 3 || value == 5)
            let ml = (value == 6)
            let mr = (value == 6)

            // (TC/BC no se usan en este tamaño)
            let tc = false
            let bc = false

            return VStack(spacing: 6) {
                HStack(spacing: 6) {
                    pipDot(tl, pipColor)
                    pipDot(tc, pipColor)
                    pipDot(tr, pipColor)
                }
                HStack(spacing: 6) {
                    pipDot(ml, pipColor)
                    pipDot(mc, pipColor)
                    pipDot(mr, pipColor)
                }
                HStack(spacing: 6) {
                    pipDot(bl, pipColor)
                    pipDot(bc, pipColor)
                    pipDot(br, pipColor)
                }
            }
        }
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

    private func barPip(isBlack: Bool) -> some View {
        Circle()
            .fill(isBlack ? Color(.label) : Color(.systemBackground))
            .overlay(Circle().stroke(Color(.separator), lineWidth: 1))
            .frame(width: 10, height: 10)
    }

    private func barPuck(count: Int, isBlack: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isBlack ? Color(.label) : Color(.systemBackground))
                .overlay(Circle().stroke(Color(.separator), lineWidth: 1))

            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isBlack ? .white : .black)
        }
        .frame(width: 22, height: 22)
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

        let isCurrentBar = (current == ownerPiece)
        let needsAttention = isCurrentBar && (count > 0)
        let isBlocked = needsAttention && barHasNoLegalEntry

        let borderColor: Color =
            isBlocked ? Color.orange :
            (needsAttention ? Color.blue : Color.clear)

        let borderWidth: CGFloat = needsAttention ? 3 : 0

        // Visual de fichas en BAR (pips + puck)
        let visiblePips = min(count, 5)
        let extra = max(0, count - visiblePips)
        let isBlack = (ownerPiece == .black)

        return VStack(spacing: 2) {
            Rectangle()
                .fill(Color.gray.opacity(0.30))
                .frame(width: width, height: height)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .overlay(
                    ZStack {
                        if count > 0 {
                            VStack(spacing: 3) {
                                ForEach(0..<visiblePips, id: \.self) { _ in
                                    barPip(isBlack: isBlack)
                                }
                                if extra > 0 {
                                    Text("+\(extra)")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)

                            barPuck(count: count, isBlack: isBlack)
                        }
                    }
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
        // ✅ BLOQUEO DE TAPS EN EL TABLERO cuando hay BAR
        .allowsHitTesting(!barHasPiecesForCurrent)
        .opacity(barHasPiecesForCurrent ? 0.55 : 1.0)
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
