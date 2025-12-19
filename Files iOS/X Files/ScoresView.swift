import SwiftUI

struct ScoresView: View {

    @Binding var equipos: [Equipo]

    // Motor de turnos
    @StateObject private var turnos: TurnosEngine

    // Compat (recibido desde AsignacionView)
    private let _ordenJugadoresRecibido: [String]

    // Reglas PAR/IMPAR (7 vs 7) + #8 neutral
    private let bolasPar = [2, 4, 6, 10, 12, 14, 15]
    private let bolasImpar = [1, 3, 5, 7, 9, 11, 13]

    // Registro real de bolas metidas
    @State private var metidasPar: Set<Int> = []
    @State private var metidasImpar: Set<Int> = []

    // Tracking (para poder desmarcar)
    @State private var bolaAtribuidaA: [Int: TipoEquipo] = [:]
    @State private var bolaScorerNombre: [Int: String] = [:]

    // #8
    @State private var bola8Resuelta = false
    @State private var ganadorPor8: TipoEquipo? = nil
    @State private var bola8ScorerNombre: String? = nil

    // Picker de bola (solo jugador en turno)
    @State private var mostrarPickerBola = false
    @State private var pickerTipoSeleccionado: TipoEquipo = .par

    // Resultados
    enum AccionPostResultados { case reset, nueva }
    @State private var mostrarResultados = false
    @State private var accionPendiente: AccionPostResultados = .reset

    // Home “infalible”
    @State private var mostrarHome = false
    @State private var irAlHomePendiente = false

    // --------------------------------------------------------------
    // MARK: - INITs (compatibles con tus llamadas)
    // --------------------------------------------------------------

    /// ScoresView(equipos: $equipos)
    init(equipos: Binding<[Equipo]>) {
        self._equipos = equipos
        self._turnos = StateObject(wrappedValue: TurnosEngine(equipos: equipos.wrappedValue))
        self._ordenJugadoresRecibido = []
    }

    /// ✅ El que usa tu AsignacionView:
    /// ScoresView(equipos: $equipos, turnos: turnos, ordenJugadores: ordenJugadores)
    init(equipos: Binding<[Equipo]>, turnos: TurnosEngine, ordenJugadores: [String] = []) {
        self._equipos = equipos
        self._turnos = StateObject(wrappedValue: turnos)
        self._ordenJugadoresRecibido = ordenJugadores
    }

    /// Posicional legacy
    init(equipos: Binding<[Equipo]>, _ turnos: TurnosEngine, _ ordenJugadores: [String]) {
        self._equipos = equipos
        self._turnos = StateObject(wrappedValue: turnos)
        self._ordenJugadoresRecibido = ordenJugadores
    }

    // --------------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------------
    var body: some View {

        ScrollView {
            VStack(spacing: 10) {

                bannerEstadoPartida

                cardTurnos

                cardRegistroBolas

                ForEach($equipos) { $equipo in
                    tarjetaEquipo($equipo)
                }

                Spacer().frame(height: 18)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Puntajes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                Button {
                    sincronizarTotales()
                    accionPendiente = .reset
                    mostrarResultados = true
                } label: { Text("Nueva") }

                Button {
                    sincronizarTotales()
                    accionPendiente = .nueva
                    mostrarResultados = true
                } label: { Text("Finalizar") }
            }
        }
        .sheet(isPresented: $mostrarResultados) {
            ResultadosSheet(
                textoBannerFinal: textoBannerFinal,
                equipos: equipos,
                accion: accionPendiente,
                onResetConfirmado: {
                    resetTodo()
                    mostrarResultados = false
                },
                onNuevaConfirmado: {
                    resetTodo()
                    irAlHomePendiente = true
                    mostrarResultados = false
                }
            )
        }
        .onChange(of: mostrarResultados) { _, mostrando in
            if !mostrando && irAlHomePendiente {
                irAlHomePendiente = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    mostrarHome = true
                }
            }
        }
        .fullScreenCover(isPresented: $mostrarHome) {
            NavigationStack {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    HomeView()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancelar") { mostrarHome = false }
                            .font(.footnote)
                    }
                }
            }
            .interactiveDismissDisabled(true)
        }
        .onAppear {
            resetPuntajesSolo()
        }
        .onChange(of: ganadorPor8) { _, nuevo in
            guard nuevo != nil else { return }
            sincronizarTotales()
            accionPendiente = .reset
            mostrarResultados = true
        }
        .sheet(isPresented: $mostrarPickerBola) {
            pickerBolaSheet
        }
    }

    // --------------------------------------------------------------
    // MARK: - UI Cards
    // --------------------------------------------------------------

    private var cardTurnos: some View {
        VStack(spacing: 8) {

            HStack(spacing: 10) {
                Text("Empieza: \(turnos.empiezaPartida.titulo)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Toggle("Auto", isOn: $turnos.modoAutoAvance)
                    .labelsHidden()

                Button {
                    turnos.siguienteTurno()
                } label: {
                    Text("Siguiente Turno")
                        .font(.subheadline.bold())
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            HStack(spacing: 10) {
                Circle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 18, height: 18)
                    .overlay(Text("8").font(.caption2.bold()).foregroundColor(.white))
                    .opacity(turnos.bolaEnManoParaSiguiente ? 1 : 0.30)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Turno")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(turnos.turnoActual.tipo.titulo) — \(turnos.turnoActual.jugadorNombre)")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text("Equipo #\(turnos.turnoActual.equipoNumero)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if turnos.bolaEnManoParaSiguiente {
                    Text("Bola en mano")
                        .font(.caption.bold())
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.orange.opacity(0.22))
                        .cornerRadius(10)
                }
            }

            Button {
                // Falta: NO suma, y pasa turno (en Auto también)
                turnos.registrarTiro(anotoBolaValida: false, fueFalta: true)
            } label: {
                Text("Falta: Blanca / Bola rival")
                    .font(.subheadline.bold())
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.18))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var cardRegistroBolas: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("Registro de Bolas")
                    .font(.headline)

                Spacer()

                Button("Reset") { resetBolas() }
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PAR")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                    gridBolas(bolasPar, tipo: .par)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("IMPAR")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    gridBolas(bolasImpar, tipo: .impar)
                }
            }

            Divider().padding(.top, 2)

            if !bola8Resuelta, (metidasPar.count == 7 || metidasImpar.count == 7) {
                let t = (metidasPar.count == 7) ? "🎱 PAR ya puede cantar la 8" : "🎱 IMPAR ya puede cantar la 8"
                Text(t)
                    .font(.subheadline.bold())
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.18))
                    .cornerRadius(12)
            }

            Text("Bola 8 (negra) — debe ser la última")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {

                Button { marcarBola8(para: .par) } label: {
                    Text("8 para PAR")
                        .font(.subheadline.bold())
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!habilitadaBola8(para: .par))

                Button { marcarBola8(para: .impar) } label: {
                    Text("8 para IMPAR")
                        .font(.subheadline.bold())
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!habilitadaBola8(para: .impar))

                Circle()
                    .fill(Color.gray.opacity(0.22))
                    .frame(width: 32, height: 32)
                    .overlay(Text("8").font(.caption.bold()))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private func gridBolas(_ bolas: [Int], tipo: TipoEquipo) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(bolas, id: \.self) { n in
                bolaChip(numero: n, tipo: tipo)
            }
        }
    }

    // Visual + permite DESMARCAR tocando (por si te equivocaste).
    private func bolaChip(numero: Int, tipo: TipoEquipo) -> some View {
        let marcada = (tipo == .par) ? metidasPar.contains(numero) : metidasImpar.contains(numero)
        let color: Color = (tipo == .par) ? .blue : .red

        return Button {
            // Solo para corregir (desmarcar). Para marcar: usa el "+" del jugador en turno.
            if marcada { desmarcarBola(numero: numero) }
        } label: {
            Circle()
                .fill(marcada ? color.opacity(0.92) : Color.gray.opacity(0.14))
                .frame(width: 34, height: 34)
                .overlay(
                    Text("\(numero)")
                        .font(.caption.bold())
                        .foregroundColor(marcada ? .white : .primary)
                )
        }
        .buttonStyle(.plain)
    }

    // --------------------------------------------------------------
    // MARK: - Banner
    // --------------------------------------------------------------

    private var bannerEstadoPartida: some View {
        Text(textoBannerVivo)
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.green.opacity(0.78))
            .cornerRadius(14)
    }

    private var textoBannerVivo: String {
        let p = totalParVivo
        let i = totalImparVivo

        if bola8Resuelta, ganadorPor8 != nil { return textoBannerFinal }

        if p == i { return "VAN EMPATANDO — \(p) BOLAS" }
        if p > i { return "VA GANANDO PAR — \(p) BOLAS" }
        return "VA GANANDO IMPAR — \(i) BOLAS"
    }

    private var textoBannerFinal: String {
        let p = totalParFinal
        let i = totalImparFinal
        if p == i { return "🤝 EMPATE — \(p) BOLAS" }
        if p > i { return "🏆 GANÓ PAR — \(p) BOLAS" }
        return "🏆 GANÓ IMPAR — \(i) BOLAS"
    }

    private var totalParVivo: Int { metidasPar.count }
    private var totalImparVivo: Int { metidasImpar.count }

    private var totalParFinal: Int {
        let plus8 = (bola8Resuelta && ganadorPor8 == .par && bola8ScorerNombre != nil) ? 1 : 0
        return metidasPar.count + plus8
    }

    private var totalImparFinal: Int {
        let plus8 = (bola8Resuelta && ganadorPor8 == .impar && bola8ScorerNombre != nil) ? 1 : 0
        return metidasImpar.count + plus8
    }

    // --------------------------------------------------------------
    // MARK: - “+” solo jugador en turno
    // --------------------------------------------------------------
    private func esJugadorDeTurno(_ nombre: String) -> Bool {
        nombre == turnos.turnoActual.jugadorNombre
    }

    private var pickerBolaSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {

                Text("Anotar bola metida")
                    .font(.headline)
                    .padding(.top, 8)

                Picker("", selection: $pickerTipoSeleccionado) {
                    Text("PAR").tag(TipoEquipo.par)
                    Text("IMPAR").tag(TipoEquipo.impar)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    let bolas = (pickerTipoSeleccionado == .par) ? bolasPar : bolasImpar
                    let metidas = (pickerTipoSeleccionado == .par) ? metidasPar : metidasImpar
                    let disponibles = bolas.filter { !metidas.contains($0) }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(disponibles, id: \.self) { n in
                            Button {
                                marcarBolaYActualizar(numero: n, tipoBola: pickerTipoSeleccionado)
                                mostrarPickerBola = false
                            } label: {
                                Circle()
                                    .fill((pickerTipoSeleccionado == .par ? Color.blue : Color.red).opacity(0.92))
                                    .frame(width: 46, height: 46)
                                    .overlay(Text("\(n)").font(.headline.bold()).foregroundColor(.white))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                }

                Button("Cerrar") { mostrarPickerBola = false }
                    .font(.headline)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
        }
        // ✅ FIX DEFINITIVO (evita "ambiguous" en tu Xcode)
        .presentationDetents(Set<PresentationDetent>([.medium, .large]))
        // ✅ FIX: fuerza el tipo correcto cada vez que se abre (elimina el bug “a veces”)
        .onAppear {
            pickerTipoSeleccionado = turnos.turnoActual.tipo
        }
        .onChange(of: turnos.turnoActual) { _, _ in
            pickerTipoSeleccionado = turnos.turnoActual.tipo
        }
    }

    // --------------------------------------------------------------
    // MARK: - Lógica bolas
    // --------------------------------------------------------------

    private func marcarBolaYActualizar(numero: Int, tipoBola: TipoEquipo) {

        guard !bola8Resuelta else { return }

        // evitar duplicados
        if tipoBola == .par, metidasPar.contains(numero) { return }
        if tipoBola == .impar, metidasImpar.contains(numero) { return }

        let tipoTurno = turnos.turnoActual.tipo
        let anotoValida = (tipoBola == tipoTurno)

        // Si mete rival: suma al rival + bola en mano + pasa turno (en Auto)
        let fueFalta = !anotoValida

        // Individual SOLO si fue válida para el tirador
        let scorer = anotoValida ? turnos.turnoActual.jugadorNombre : nil

        // 1) guardar set
        if tipoBola == .par { metidasPar.insert(numero) } else { metidasImpar.insert(numero) }

        // 2) tracking
        bolaAtribuidaA[numero] = tipoBola
        if let scorer { bolaScorerNombre[numero] = scorer }

        // 3) sync totals “real”
        sincronizarTotales()

        // 4) Turnos (Auto)
        if turnos.modoAutoAvance {
            turnos.registrarTiro(anotoBolaValida: anotoValida, fueFalta: fueFalta)
        }
    }

    private func desmarcarBola(numero: Int) {
        guard let tipo = bolaAtribuidaA[numero] else { return }

        if tipo == .par { metidasPar.remove(numero) } else { metidasImpar.remove(numero) }
        bolaAtribuidaA.removeValue(forKey: numero)
        bolaScorerNombre.removeValue(forKey: numero)

        sincronizarTotales()
    }

    // --------------------------------------------------------------
    // MARK: - Bola 8
    // --------------------------------------------------------------

    private func habilitadaBola8(para tipo: TipoEquipo) -> Bool {
        guard !bola8Resuelta else { return false }
        if tipo == .par { return metidasPar.count == 7 }
        return metidasImpar.count == 7
    }

    private func marcarBola8(para tipo: TipoEquipo) {

        guard !bola8Resuelta else { return }

        let tiene7 = (tipo == .par) ? (metidasPar.count == 7) : (metidasImpar.count == 7)

        bola8Resuelta = true

        if tiene7 {
            ganadorPor8 = tipo
            bola8ScorerNombre = turnos.turnoActual.jugadorNombre
        } else {
            // 8 adelantada -> gana el otro
            ganadorPor8 = (tipo == .par) ? .impar : .par
            bola8ScorerNombre = nil
        }

        sincronizarTotales()
    }

    // --------------------------------------------------------------
    // MARK: - Tarjeta equipo (+ solo turno)
    // --------------------------------------------------------------
    private func tarjetaEquipo(_ equipo: Binding<Equipo>) -> some View {

        let color: Color = (equipo.wrappedValue.tipo == .par) ? .blue : .red

        return VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("Equipo #\(equipo.wrappedValue.numero)  \(equipo.wrappedValue.tipo.titulo)")
                    .font(.subheadline.bold())
                    .foregroundColor(color)

                Spacer()

                Text("Total: \(equipo.wrappedValue.puntajeActual)")
                    .font(.subheadline.bold())
            }

            Divider()

            ForEach(equipo.wrappedValue.jugadores.indices, id: \.self) { idx in
                let nombre = equipo.wrappedValue.jugadores[idx].nombre
                let indiv = (idx < equipo.wrappedValue.puntajeIndividual.count) ? equipo.wrappedValue.puntajeIndividual[idx] : 0
                let enTurno = esJugadorDeTurno(nombre)

                HStack(spacing: 10) {
                    Text(nombre)
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)

                    Spacer()

                    Text("\(indiv)")
                        .font(.subheadline.bold())
                        .frame(width: 30, alignment: .trailing)

                    if enTurno {
                        Button {
                            pickerTipoSeleccionado = turnos.turnoActual.tipo
                            DispatchQueue.main.async {
                                mostrarPickerBola = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    // --------------------------------------------------------------
    // MARK: - Sincronizar totales (evita desajustes)
    // --------------------------------------------------------------
    private func sincronizarTotales() {

        // 1) reset equipos
        for i in equipos.indices {
            equipos[i].puntajeActual = 0
            if equipos[i].puntajeIndividual.count != equipos[i].jugadores.count {
                equipos[i].puntajeIndividual = Array(repeating: 0, count: equipos[i].jugadores.count)
            } else {
                for j in equipos[i].puntajeIndividual.indices { equipos[i].puntajeIndividual[j] = 0 }
            }
        }

        // 2) sumar bolas normales (1 punto por bola)
        for (bola, tipoEq) in bolaAtribuidaA {

            if let idxEq = equipos.firstIndex(where: { $0.tipo == tipoEq }) {
                equipos[idxEq].puntajeActual += 1
            }

            if let scorer = bolaScorerNombre[bola],
               let (eIdx, jIdx) = encontrarJugador(scorer) {
                asegurarTamanosIndividual(enEquipo: eIdx)
                equipos[eIdx].puntajeIndividual[jIdx] += 1
            }
        }

        // 3) sumar la 8 SOLO si fue válida (tiene7 y scorer existe)
        if bola8Resuelta, let ganador = ganadorPor8, let scorer8 = bola8ScorerNombre {

            if let idxEq = equipos.firstIndex(where: { $0.tipo == ganador }) {
                equipos[idxEq].puntajeActual += 1
            }

            if let (eIdx, jIdx) = encontrarJugador(scorer8) {
                asegurarTamanosIndividual(enEquipo: eIdx)
                equipos[eIdx].puntajeIndividual[jIdx] += 1
            }
        }
    }

    // --------------------------------------------------------------
    // MARK: - Reset
    // --------------------------------------------------------------
    private func resetBolas() {
        metidasPar.removeAll()
        metidasImpar.removeAll()
        bolaAtribuidaA.removeAll()
        bolaScorerNombre.removeAll()

        bola8Resuelta = false
        ganadorPor8 = nil
        bola8ScorerNombre = nil

        sincronizarTotales()
    }

    private func resetPuntajesSolo() {
        for i in equipos.indices {
            equipos[i].puntajeActual = 0
            if equipos[i].puntajeIndividual.count != equipos[i].jugadores.count {
                equipos[i].puntajeIndividual = Array(repeating: 0, count: equipos[i].jugadores.count)
            } else {
                for j in equipos[i].puntajeIndividual.indices { equipos[i].puntajeIndividual[j] = 0 }
            }
        }
    }

    private func resetTodo() {
        resetBolas()
    }

    // --------------------------------------------------------------
    // MARK: - Helpers
    // --------------------------------------------------------------
    private func encontrarJugador(_ nombre: String) -> (Int, Int)? {
        for eIdx in equipos.indices {
            if let jIdx = equipos[eIdx].jugadores.firstIndex(where: { $0.nombre == nombre }) {
                return (eIdx, jIdx)
            }
        }
        return nil
    }

    private func asegurarTamanosIndividual(enEquipo idx: Int) {
        if equipos[idx].puntajeIndividual.count != equipos[idx].jugadores.count {
            equipos[idx].puntajeIndividual = Array(repeating: 0, count: equipos[idx].jugadores.count)
        }
    }
}

// --------------------------------------------------------------
// MARK: - Sheet de Resultados
// --------------------------------------------------------------
private struct ResultadosSheet: View {

    let textoBannerFinal: String
    let equipos: [Equipo]
    let accion: ScoresView.AccionPostResultados

    let onResetConfirmado: () -> Void
    let onNuevaConfirmado: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {

                    HStack {
                        Text("Resultados")
                            .font(.headline.bold())
                        Spacer()
                    }

                    Text(textoBannerFinal)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.green.opacity(0.78))
                        .cornerRadius(14)

                    VStack(spacing: 10) {
                        ForEach(equipos) { eq in
                            let color: Color = (eq.tipo == .par) ? .blue : .red

                            VStack(alignment: .leading, spacing: 8) {

                                HStack {
                                    Text("Equipo #\(eq.numero)  \(eq.tipo.titulo)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(color)

                                    Spacer()

                                    Text("Total: \(eq.puntajeActual)")
                                        .font(.subheadline.bold())
                                }

                                Divider()

                                ForEach(eq.jugadores.indices, id: \.self) { idx in
                                    let nombre = eq.jugadores[idx].nombre
                                    let puntos = (idx < eq.puntajeIndividual.count) ? eq.puntajeIndividual[idx] : 0

                                    HStack {
                                        Text(nombre)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                        Spacer()
                                        Text("\(puntos)")
                                            .font(.caption.bold())
                                    }
                                }
                            }
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                    }

                    Button {
                        switch accion {
                        case .reset: onResetConfirmado()
                        case .nueva: onNuevaConfirmado()
                        }
                        dismiss()
                    } label: {
                        Text(accion == .reset ? "Nueva Partida" : "Ir al Inicio")
                            .font(.subheadline.bold())
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(accion == .reset ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancelar")
                            .font(.subheadline.bold())
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.18))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                    }
                }
                .padding()
            }
        }
    }
}
