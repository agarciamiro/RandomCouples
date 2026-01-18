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

    // ✅ OFF (fichas retiradas) — solo UI por ahora
    @State private var offCasa: Int = 0


    // ✅ SERIE (acumulado) — UI-only por ahora
    @State private var serieCasa: Int = 0
    @State private var serieVisita: Int = 0
    // MARK: - Winner banner

    private var winnerSideLabel: String? {
        if offCasa >= 15 { return "CASA" }
        if offVisita >= 15 { return "VISITA" }
        return nil
    }

    private var winnerTitleText: String {
        "¡GANADOR \(winnerSideLabel ?? "")!"
    }

    @ViewBuilder
    private var winnerOverlay: some View {
        if winnerSideLabel != nil && showWinnerOverlay {
            ZStack {
                Color.black.opacity(0.22)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { } // captura taps (no deja tocar el tablero)

            VStack(spacing: 8) {
                    Text(winnerTitleText)
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text(winnerSideLabel == "CASA" ? "Casa (P1)" : "Visita (P2)")
                        .font(.footnote.bold())
                        .foregroundColor(.white.opacity(0.9))

                    Button {
                        showWinnerOverlay = false
                showRematchPrompt = true
                    } label: {
                        Text("Continuar")
                            .font(.headline.bold())
                .font(.footnote.bold())
                .controlSize(.small)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundColor(.black)
                }
                .padding(16)
                .frame(maxWidth: 320)
                .background(Color.black.opacity(0.55))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    @State private var offVisita: Int = 0

    // ✅ B2-1: candidato OFF (solo lógica, sin UI)
    @State private var offCandidateFrom: Int? = nil
    @State private var offCandidateDie: Int? = nil

    @State private var offCandidate: (from: Int, die: Int)? = nil  // B2: destino OFF disponible

    // ✅ MVP B1: selección + destinos posibles
    @State private var selectedFrom: Int? = nil
    @State private var highlightedTo: Set<Int> = []
    @State private var lastComputedMoves: [Int: Int] = [:] // destino -> dado usado (valor)

    @State private var showWinnerOverlay: Bool = true
@State private var showRematchPrompt: Bool = false
    @State private var showRematchDiceRoulette: Bool = false
    @State private var matchFinalizedForSeries: Bool = false

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

            // ✅ UX A1: espejo de dados en el centro (solo visual)
            HStack(spacing: 10) {
                dieBox(value: dieValueForUI(index: 0))

                Text("+")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                dieBox(value: dieValueForUI(index: 1))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 6)
            .padding(.bottom, 2)
            .offset(x: 6, y: -17)

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
                            EmptyView()
                                .padding(.horizontal, 24)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }

            // Text(boardHintText)
            //     .font(.footnote)
            //     .foregroundColor(.secondary)
            //     .padding(.bottom, 86)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Button("Regresar") {
                        // TODO: implementar undo/regresar jugada
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)

                    Button("Cancelar") {
                        clearSelection()
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)

                    Button("Confirmar") {
                        // TODO: implementar confirmar jugadas
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                }
                .font(.footnote.bold())
                .controlSize(.small)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)

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
        }
        .overlay { winnerOverlay }
.navigationTitle("Tablero")

        .sheet(isPresented: $showRematchDiceRoulette) {
            NavigationStack {
                BackgammonDiceRouletteView(colors: colors) { _ in
                    // STEP1: solo cerramos la ruleta (sin reset aún)
                    showRematchDiceRoulette = false
                    showRematchPrompt = false
                }
                .navigationTitle("Ruleta")
                .navigationBarTitleDisplayMode(.inline)
            }
        }


        .alert("¿Jugar otra partida?", isPresented: $showRematchPrompt) {
            Button("Sí") {
                if !matchFinalizedForSeries {
                    if offCasa >= 15 { serieCasa += currentMatchMultiplier }
                    else if offVisita >= 15 { serieVisita += currentMatchMultiplier }
                    matchFinalizedForSeries = true
                }
                showRematchDiceRoulette = true
                // resetMatchKeepSeries()  // (STEP1: aún no reseteamos)
            }
            Button("No", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Se mantienen colores y se acumula el marcador de la serie.")
        }

        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.bold())
                        .padding(8)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Cerrar")
            }
        }
        .onAppear {
            clearSelection()

            // ✅ Auto-seleccionar BAR si hay fichas en BAR y hay dados activos
            if barHasPiecesForCurrent && !remainingDiceValues.isEmpty {
                selectedFrom = Self.barSourceIndex
                computeHighlights(from: Self.barSourceIndex)
            }
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
            VStack(spacing: 8) {
            // Text("TABLERO (24 posiciones)")
            //     .font(.headline)
            //     .frame(maxWidth: .infinity, alignment: .leading)
            //     .padding(.horizontal, 16)
            //     .padding(.top, 10)

            // ✅ Layout: izquierda info, centro dados + dirección, derecha jugador
            HStack(alignment: .center, spacing: 14) {

                // IZQUIERDA
                VStack(alignment: .center, spacing: 4) {
                    Text("Turno \(turnNumber)")
                        .font(.caption.bold())

                    // ✅ Contador de movimientos restantes (dobles=4)
                    if !dice.isEmpty {
                        let total = dice.count
                        let left = remainingDiceValues.count
                        let used = total - left

                        Text("Movimientos: \(used)/\(total)")
                            .font(.footnote.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                            .foregroundColor(.secondary)
                    }

                }

                Spacer(minLength: 0)

                // CENTRO (DADOS + DIRECCIÓN)
                VStack(spacing: 6) {
                    // ✅ UX A1: dados se muestran al centro (se ocultan aquí)
Spacer(minLength: 0)
                serieBadge

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
                    Text("Turno de:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    Text(current == .white ? "BLANCAS" : "NEGRAS")
                        .font(.headline.bold())
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(current == .white ? Color(.systemGray6) : Color.black)
                        .foregroundColor(current == .white ? .black : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
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
                .padding(.bottom, 86)
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
            .allowsHitTesting(false)
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
            .allowsHitTesting(false)
        }
    }

    private var directionIndicatorText: String {
        if current == casaPiece {
            return "⬅️ CASA: 24 → 1 · ABAJO"
        } else {
            return "➡️ VISITA: 1 → 24 · ARRIBA"
        }
    }

    private func nameForCurrent() -> String {
        return (current == casaPiece) ? casaName : visitaName
    }

    
    // MARK: - B1: Bearing off (detección "todas en casa") — SOLO LÓGICA (sin UI)

    private var homeRangeForCurrent: ClosedRange<Int> {
        // CASA: 1..6, VISITA: 19..24
        return (current == casaPiece) ? 1...6 : 19...24
    }

    private var canBearOffCurrent: Bool {
        // No se puede retirar si hay fichas en BAR
        if barHasPiecesForCurrent { return false }

        // Contar fichas del jugador actual fuera de su home board
        for i in 1...24 {
            guard let stack = points[i] else { continue }
            if stack.count > 0, stack.piece == current {
                if !homeRangeForCurrent.contains(i) {
                    return false
                }
            }
        }
        return true
    }


    // MARK: - B2: OFF highlight (placeholder para compilar)
    // Nota: en B2 real lo haremos dinámico (según si hay retiro posible).
    private var offHighlightIsVisita: Bool { offCandidateFrom != nil && current == visitaPiece }
    private var offHighlightIsCasa: Bool { offCandidateFrom != nil && current == casaPiece }


    // MARK: - B2-1: cálculo interno de OFF posible (sin UI, sin retirar)

    private func hasCheckerFurtherInHome(from index: Int) -> Bool {
        // Solo se usa cuando canBearOffCurrent == true (todos en casa)
        if current == casaPiece {
            // CASA home 1..6: "más lejos" = puntos mayores
            if index >= 6 { return false }
            for i in (index + 1)...6 {
                if let st = points[i], st.count > 0, st.piece == current { return true }
            }
            return false
        } else {
            // VISITA home 19..24: "más lejos" = puntos menores
            if index <= 19 { return false }
            for i in 19...(index - 1) {
                if let st = points[i], st.count > 0, st.piece == current { return true }
            }
            return false
        }
    }

    private func computeOffCandidate(from index: Int) {
        offCandidateFrom = nil
        offCandidateDie = nil

        guard canBearOffCurrent else { return }
        guard homeRangeForCurrent.contains(index) else { return }

        let diceValues = remainingDiceValues
        guard !diceValues.isEmpty else { return }

        let dir = moveDirectionForCurrent()

        for v in diceValues {
            let to = index + (dir * v)

            // Exacto
            if current == casaPiece && to == 0 {
                offCandidateFrom = index
                offCandidateDie = v
                return
            }
            if current == visitaPiece && to == 25 {
                offCandidateFrom = index
                offCandidateDie = v
                return
            }

            // Overshoot permitido (regla estándar)
            if current == casaPiece && to < 1 {
                if !hasCheckerFurtherInHome(from: index) {
                    offCandidateFrom = index
                    offCandidateDie = v
                    return
                }
            }
            if current == visitaPiece && to > 24 {
                if !hasCheckerFurtherInHome(from: index) {
                    offCandidateFrom = index
                    offCandidateDie = v
                    return
                }
            }
        }
    }

    // MARK: - B3-1: ejecutar retiro OFF (solo CASA)
    private func executeBearOffCasa() {
        guard current == casaPiece else { return }
        guard canBearOffCurrent else { return }
        guard let from = offCandidateFrom, let die = offCandidateDie else { return }

        // Quitar 1 ficha del punto 'from'
        guard var src = points[from], src.count > 0, src.piece == current else { return }
        src.count -= 1
        if src.count == 0 { src.piece = .none }
        points[from] = src

        // Consumir el dado usado
        consumeOneDie(value: die)

        // Incrementar OFF CASA
        offCasa += 1

        // Limpieza / recalcular
        clearSelection()

        // Si aún hay dados disponibles, queda listo para seguir jugando
        // (si quedan fichas en BAR, post-move logic ya se encarga cuando selecciones)
    }

    // MARK: - B3-2: ejecutar retiro OFF (VISITA)
    private func executeBearOffVisita() {
        guard current == visitaPiece else { return }
        guard canBearOffCurrent else { return }
        guard let from = offCandidateFrom, let die = offCandidateDie else { return }

        // Quitar 1 ficha del punto 'from'
        guard var src = points[from], src.count > 0, src.piece == current else { return }
        src.count -= 1
        if src.count == 0 { src.piece = .none }
        points[from] = src

        // Consumir el dado usado
        consumeOneDie(value: die)

        // Incrementar OFF VISITA
        offVisita += 1

        // Limpieza / recalcular
        clearSelection()
    }




    // MARK: - STONE SERIE: SERIE + Multiplicador (UI)

    private var currentMatchMultiplier: Int {
        let t = max(0, startResult.tieCount)
        return max(1, 1 << t) // 2^t
    }

    private var serieBadge: some View {
        let casaPlayer = (casaPiece == .black) ? colors.blackPlayer : colors.whitePlayer
        let visitaPlayer = (visitaPiece == .black) ? colors.blackPlayer : colors.whitePlayer

        func nameChip(_ name: String, isBlack: Bool) -> some View {
            Text(name)
                .font(.caption2.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isBlack ? Color(.label) : Color(.systemGray5))
                .foregroundColor(isBlack ? .white : .black)
                .clipShape(Capsule())
        }

        func scoreCircle(_ value: Int) -> some View {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))

                Text("\(value)")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
            }
            .frame(width: 54, height: 54)
        }

        return VStack(spacing: 6) {
            HStack(spacing: 18) {
                VStack(spacing: 6) {
                    scoreCircle(serieCasa)
                    nameChip(casaPlayer, isBlack: (casaPiece == .black))
                }

                VStack(spacing: 6) {
                    scoreCircle(serieVisita)
                    nameChip(visitaPlayer, isBlack: (visitaPiece == .black))
                }
            }

            Text("Multiplicador: x\(currentMatchMultiplier)")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .offset(y: -24)
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
            // 3x3: tl tc tr / ml mc mr / bl bc br
            let tl: Bool, tc: Bool, tr: Bool
            let ml: Bool, mc: Bool, mr: Bool
            let bl: Bool, bc: Bool, br: Bool

            switch value {
            case 1:
                tl=false; tc=false; tr=false
                ml=false; mc=true;  mr=false
                bl=false; bc=false; br=false
            case 2:
                tl=true;  tc=false; tr=false
                ml=false; mc=false; mr=false
                bl=false; bc=false; br=true
            case 3:
                tl=true;  tc=false; tr=false
                ml=false; mc=true;  mr=false
                bl=false; bc=false; br=true
            case 4:
                tl=true;  tc=false; tr=true
                ml=false; mc=false; mr=false
                bl=true;  bc=false; br=true
            case 5:
                tl=true;  tc=false; tr=true
                ml=false; mc=true;  mr=false
                bl=true;  bc=false; br=true
            case 6:
                tl=true;  tc=false; tr=true
                ml=true;  mc=false; mr=true
                bl=true;  bc=false; br=true
            default:
                tl=false; tc=false; tr=false
                ml=false; mc=false; mr=false
                bl=false; bc=false; br=false
            }

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
                VStack(spacing: 6) {
                    offBox(title: "OFF", subtitle: "VISITA", value: offVisita, highlight: offHighlightIsVisita)
                .allowsHitTesting(offHighlightIsVisita)
                .onTapGesture {
                    executeBearOffVisita()
                }
                    barCell(slot: .topVisita, width: barW, height: cellH)
                }

                ForEach(topRight, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }
            }

            HStack(spacing: spacing) {
                ForEach(botLeft, id: \.self) { idx in
                    pointCell(index: idx, cellW: cellW, cellH: cellH)
                }

                // ✅ BAR INFERIOR = CASA (y muestra su color real con B/N)
                VStack(spacing: 6) {
                    barCell(slot: .bottomCasa, width: barW, height: cellH)
                    offBox(title: "OFF", subtitle: "CASA", value: offCasa, highlight: offHighlightIsCasa)
                .allowsHitTesting(offHighlightIsCasa)
                .onTapGesture {
                    executeBearOffCasa()
                }
                }

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

    
    // MARK: - OFF boxes (UI only)
    private func offBox(title: String, subtitle: String, value: Int, highlight: Bool) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)

            Text("\(value)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
        }
        .frame(width: 40, height: 40)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(highlight ? Color.green : Color(.systemGray4), lineWidth: highlight ? 3 : 1)
        )
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
                .fill(needsAttention ? Color.blue.opacity(0.10) : Color.gray.opacity(0.30))
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            (isBlocked ? Color.orange : (needsAttention ? Color.blue : Color.clear))
                                .opacity(needsAttention ? 0.12 : 0.0)
                        )
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .overlay(
                    ZStack {
                        if isBlocked {
                            Text("BLOQUEADO")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.75))
                                .clipShape(Capsule())
                                .offset(y: -2)
                        }
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
        .allowsHitTesting(!barHasPiecesForCurrent || highlightedTo.contains(index))
        .opacity(barHasPiecesForCurrent && !highlightedTo.contains(index) ? 0.55 : 1.0)
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
        offCandidate = nil

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
    

        // B2-2: si aplica, calcular candidato OFF (solo highlight)
        computeOffCandidate(from: index)
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


    // ✅ Detecta si hay al menos 1 jugada legal con los dados restantes.
    private func hasAnyLegalMove() -> Bool {
        let diceValues = remainingDiceValues
        if diceValues.isEmpty { return false }

        // 1) Si hay BAR: solo entradas desde BAR
        if barHasPiecesForCurrent {
            for v in diceValues {
                let entry = barEntryPoint(forDie: v)
                if (1...24).contains(entry), isDestinationAllowed(to: entry) {
                    return true
                }
            }
            return false
        }

        // 2) Movidas normales en tablero
        let dir = moveDirectionForCurrent()
        for from in 1...24 {
            guard let stack = points[from], stack.count > 0, stack.piece == current else { continue }
            for v in diceValues {
                let to = from + (dir * v)

                // Movimiento dentro del tablero
                if (1...24).contains(to) {
                    if isDestinationAllowed(to: to) { return true }
                    continue
                }

                // 3) Bear off (si existe canBearOffCurrent)
                if canBearOffCurrent {
                    if current == casaPiece && to < 1 {
                        if !hasCheckerFurtherInHomeCasa(from: from) { return true }
                    } else if current == visitaPiece && to > 24 {
                        if !hasCheckerFurtherInHomeVisita(from: from) { return true }
                    }
                }
            }
        }
        return false
    }

    private func hasCheckerFurtherInHomeCasa(from: Int) -> Bool {
        // CASA home: 1..6. "Más allá" = puntos mayores.
        guard (1...6).contains(from) else { return false }
        if from >= 6 { return false } // ✅ evita rango inválido 7...6

        for i in (from + 1)...6 {
            if let st = points[i], st.count > 0, st.piece == current { return true }
        }
        return false
    }


    private func hasCheckerFurtherInHomeVisita(from: Int) -> Bool {
        // VISITA home: 19..24. "Más allá" = puntos menores (hacia 19).
        guard (19...24).contains(from) else { return false }
        if from <= 19 { return false } // ✅ evita rango inválido 19...18

        for i in 19...(from - 1) {
            if let st = points[i], st.count > 0, st.piece == current { return true }
        }
        return false
    }


    // MARK: - Turn management

    private var canEndTurn: Bool {
        // ✅ Si BAR está bloqueado: se permite terminar turno aunque queden dados
        if barHasPiecesForCurrent && barHasNoLegalEntry { return true }
        if !hasAnyLegalMove() { return true }
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
        if !dice.isEmpty && !hasAnyLegalMove() {
            return "No hay jugadas legales. Turno perdido: toca Continuar."
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
    
        offCandidateFrom = nil
        offCandidateDie = nil
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

    
    // MARK: - B1: Rematch (mantiene SERIE, reinicia partida)
    private func resetMatchKeepSeries() {
        showWinnerOverlay = true
        showRematchPrompt = false

        let homeColor: BGPiece = (colors.blackSide == .player1) ? .black : .white
        points = Self.standardSetup(homeColor: homeColor)

        barWhite = 0
        barBlack = 0
        offCasa = 0
        offVisita = 0

        turnNumber = 1
        current = (current == .white) ? .black : .white

        // nuevos dados
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
        matchFinalizedForSeries = false
    }

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

